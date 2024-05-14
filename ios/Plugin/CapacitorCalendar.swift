import Foundation
import Capacitor
import EventKitUI

public class CapacitorCalendar: CapacitorCalendarBase, EKEventEditViewDelegate, EKCalendarChooserDelegate {
    private var currentCreateEventContinuation: CheckedContinuation<[String], any Error>?
    private var currentSelectCalendarsContinuation: CheckedContinuation<[[String: Any]], any Error>?

    // MARK: - Permissions

    public func checkAllPermissions() -> [String: String] {
        return checkAllPermissions(entity: .event, source: #function)
    }

    @MainActor
    public func requestWriteAccessToEvents() async throws -> [String: String] {
        do {
            var granted: Bool

            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestWriteOnlyAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }

            let permisson = granted ? PermissionState.granted.rawValue : PermissionState.denied.rawValue
            return ["result": permisson]
        } catch {
            throw CapacitorCalendarError(fromError: error, source: #function)
        }
    }

    public func requestFullAccessToEvents() async throws -> String {
        return try await requestFullAccessTo(.event, source: #function)
    }

    // MARK: - Calendars

    @MainActor
    public func selectCalendarsWithPrompt(selectionStyle: Int, displayStyle: Int) async throws -> [[String: Any]] {
        guard let bridgeViewController = bridge?.viewController,
              let selectionStyle = EKCalendarChooserSelectionStyle(rawValue: selectionStyle),
              let displayStyle = EKCalendarChooserDisplayStyle(rawValue: displayStyle) else {
            throw CapacitorCalendarError(.noViewController, source: #function)
        }

        do {
            return try await withCheckedThrowingContinuation { continuation in
                let calendarChooser = EKCalendarChooser(
                    selectionStyle: selectionStyle,
                    displayStyle: displayStyle,
                    eventStore: eventStore
                )
                calendarChooser.showsDoneButton = true
                calendarChooser.showsCancelButton = true
                calendarChooser.delegate = self
                currentSelectCalendarsContinuation = continuation
                bridgeViewController.present(
                    UINavigationController(rootViewController: calendarChooser),
                    animated: true,
                    completion: nil
                )
            }
        } catch {
            throw CapacitorCalendarError(fromError: error, source: #function)
        }
    }

    // Delegate method for EKCalendarChooser presented in selectCalendarsWithPrompt()
    public func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        let selectedCalendars = calendarsToDicts(calendarChooser.selectedCalendars)
        bridge?.viewController?.dismiss(animated: true) {
            self.currentSelectCalendarsContinuation?.resume(returning: selectedCalendars)
        }
    }

    // Delegate method for EKCalendarChooser presented in selectCalendarsWithPrompt()
    public func calendarChooserDidCancel(_ calendarChooser: EKCalendarChooser) {
        bridge?.viewController?.dismiss(animated: true) {
            self.currentSelectCalendarsContinuation?.resume(returning: [])
        }
    }

    public func listCalendars(_ access: EKCalendarChooserDisplayStyle) -> [[String: Any]] {
        let calendars = calendarsToDicts(Set(eventStore.calendars(for: .event)))

        if access == EKCalendarChooserDisplayStyle.writableCalendarsOnly {
            return calendars.filter { calendar in
                return calendar["writeable"] as? Bool ?? false
            }
        } else {
            return calendars
        }
    }

    public func getDefaultCalendar() -> [String: Any]? {
        return getDefaultCalendar(for: .event, source: #function)
    }

    @MainActor
    public func openCalendar(date: Double) async throws {
        try await open(URL(string: "calshow:\(date)"), errorType: .unableToOpenCalendar, source: #function)
    }

    @MainActor
    public func createCalendar(title: String, color: String?) async throws -> String {
        let newCalendar = EKCalendar(for: .event, eventStore: eventStore)
        newCalendar.title = title
        newCalendar.source = eventStore.defaultCalendarForNewEvents?.source

        if let calendarColor = color {
            newCalendar.cgColor = UIColor(hex: calendarColor)?.cgColor
        } else {
            newCalendar.cgColor = eventStore.defaultCalendarForNewEvents?.cgColor
        }

        do {
            try eventStore.saveCalendar(newCalendar, commit: true)
        } catch {
            throw CapacitorCalendarError(fromError: error, source: #function)
        }

        return newCalendar.calendarIdentifier
    }

    @MainActor
    public func deleteCalendar(id: String) throws {
        if let calendar = eventStore.calendar(withIdentifier: id) {
            if calendar.allowsContentModifications {
                try eventStore.removeCalendar(calendar, commit: true)
            } else {
                throw CapacitorCalendarError(.noAccess, source: #function, data: "calendar/write")
            }
        } else {
            throw CapacitorCalendarError(.calendarNotFound, source: #function)
        }
    }

    // MARK: - Events

    @MainActor
    public func createEvent(with parameters: EventCreationParameters) async throws -> String {
        let newEvent = try setupCreateEvent(with: parameters, prompting: false, source: #function)

        do {
            try eventStore.save(newEvent, span: .thisEvent)
            return newEvent.eventIdentifier
        } catch {
            throw CapacitorCalendarError(.osError, source: #function, data: error.localizedDescription)
        }
    }

    @MainActor
    public func createEventWithPrompt(with parameters: EventCreationParameters) async throws -> [String] {
        let newEvent = try setupCreateEvent(with: parameters, prompting: true, source: #function)

        guard let bridgeViewController = bridge?.viewController else {
            throw CapacitorCalendarError(.noViewController, source: #function)
        }

        let eventViewController = EKEventEditViewController()
        eventViewController.event = newEvent
        eventViewController.eventStore = eventStore
        eventViewController.editViewDelegate = self

        return try await withCheckedThrowingContinuation { [bridgeViewController] continuation in
            let eventEditViewController = EKEventEditViewController()
            eventEditViewController.event = newEvent
            eventEditViewController.eventStore = eventStore
            eventEditViewController.editViewDelegate = self
            currentCreateEventContinuation = continuation
            bridgeViewController.present(eventEditViewController, animated: true, completion: nil)
        }
    }

    // Delegate for the EKEventEditViewController presented in createEventWithPrompt()
    public func eventEditViewController(
        _ controller: EKEventEditViewController,
        didCompleteWith action: EKEventEditViewAction
    ) {
        controller.dismiss(animated: true) {
            if action == .saved {
                // We have to assume that if the action is .saved, controller.event will be non-nil
                self.currentCreateEventContinuation?.resume(returning: [controller.event!.eventIdentifier])
            } else {
                self.currentCreateEventContinuation?.resume(returning: [])
            }
        }
    }

    private func setupCreateEvent(with parameters: EventCreationParameters, prompting: Bool, source: String) throws -> EKEvent {
        let fallbackStartDate = Date()
        let newEvent = EKEvent(eventStore: eventStore)

        if let calendarId = parameters.calendarId,
           let calendar = eventStore.calendar(withIdentifier: calendarId) {
            newEvent.calendar = calendar
        } else {
            if let defaultCalendar = eventStore.defaultCalendarForNewEvents {
                newEvent.calendar = defaultCalendar
            } else {
                throw CapacitorCalendarError(.noDefaultCalendar, source: source)
            }
        }

        // Make sure the event's calendar is writeable.
        guard newEvent.calendar.allowsContentModifications else {
            throw CapacitorCalendarError.noAccessForEntity(.calendar, accessType: .write, source: source)
        }

        newEvent.title = parameters.title

        if let location = parameters.location {
            newEvent.location = location
        }

        if let startDate = parameters.startDate {
            newEvent.startDate = Date(timeIntervalSince1970: startDate / 1000)
        } else if !prompting {
            newEvent.startDate = fallbackStartDate
        }

        if let endDate = parameters.endDate {
            newEvent.endDate = Date(timeIntervalSince1970: endDate / 1000)
        } else if !prompting {
            newEvent.endDate = fallbackStartDate.addingTimeInterval(3600)
        }

        if let isAllDay = parameters.isAllDay {
            newEvent.isAllDay = isAllDay
        }

        if let alertOffsetInMinutes = parameters.alertOffsetInMinutes, alertOffsetInMinutes >= 0 {
            newEvent.addAlarm(EKAlarm(relativeOffset: TimeInterval(-alertOffsetInMinutes * 60)))
        }

        return newEvent
    }

    public func listEventsInRange(
        startDate: Double,
        endDate: Double
    ) throws -> [[String: Any]] {
        let predicate = eventStore.predicateForEvents(
            withStart: Date(timeIntervalSince1970: startDate / 1000),
            end: Date(timeIntervalSince1970: endDate / 1000), calendars: nil
        )
        let events = self.eventStore.events(matching: predicate)

        return events.map { event in
            var dict = [String: Any]()
            dict["id"] = event.eventIdentifier

            for property in [
                (event.title, "title"),
                (event.location, "location"),
                (event.organizer?.name, "organizer"),
                (event.notes, "description")
            ] {
                if let value = property.0,
                   !value.isEmpty {
                    dict[property.1] = value
                }
            }

            for dateProperty in [
                (event.startDate, "startDate", "eventTimezone"),
                (event.endDate, "endDate", "eventEndTimeZone")
            ] {
                if let date = dateProperty.0 {
                    dict[dateProperty.1] = date.timeIntervalSince1970

                    if let timezone = event.timeZone,
                       let abbreviation = timezone.abbreviation(for: date) {
                        dict[dateProperty.2] = abbreviation
                    }
                }
            }

            dict["isAllDay"] = event.isAllDay
            dict["calendarId"] = event.calendar.calendarIdentifier
            return dict
        }
    }

    @MainActor
    public func deleteEventsById(ids: JSArray) async throws -> EventDeleteResults {
        var deleted: [String] = []
        var failed: [String] = []

        for id in ids {
            let strId = "\(id)"
            guard let event = eventStore.event(withIdentifier: strId),
                  event.calendar.allowsContentModifications else {
                failed.append(strId)
                continue
            }

            do {
                try eventStore.remove(event, span: .thisEvent, commit: false)
                deleted.append(strId)
            } catch {
                failed.append(strId)
            }
        }

        do {
            try eventStore.commit()
        } catch {
            failed.append(contentsOf: deleted)
            deleted.removeAll()
        }

        return EventDeleteResults(deleted: deleted, failed: failed)
    }
}
