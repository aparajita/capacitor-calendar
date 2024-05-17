//
//  Calendar+Events.swift
//  EbarooniCapacitorCalendar
//
//  Created by Aparajita on 5/16/24.
//

import Capacitor
import EventKitUI
import Foundation

struct EventCreationParameters {
    var title: String
    var calendarId: String?
    var location: String?
    var startDate: Double?
    var endDate: Double?
    var isAllDay: Bool?
    var alertOffsetInMinutes: Double?
}

struct EventDeleteResults {
    var deleted: [String]
    var failed: [String]
}

extension CapacitorCalendar {
    @MainActor
    func createEvent(with parameters: EventCreationParameters) async throws -> String {
        let newEvent = try setupCreateEvent(with: parameters, prompting: false, source: #function)

        do {
            try eventStore.save(newEvent, span: .thisEvent)
            return newEvent.eventIdentifier
        } catch {
            throw PluginError(.osError, source: #function, data: error.localizedDescription)
        }
    }

    @MainActor
    func createEventWithPrompt(with parameters: EventCreationParameters) async throws -> [String] {
        let newEvent = try setupCreateEvent(with: parameters, prompting: true, source: #function)

        guard let bridgeViewController = bridge?.viewController else {
            throw PluginError(.noViewController, source: #function)
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
            if let event = controller.event,
               action == .saved {
                self.currentCreateEventContinuation?.resume(returning: [event.eventIdentifier])
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
                throw PluginError(.noDefaultCalendar, source: source)
            }
        }

        // Make sure the event's calendar is writeable.
        guard newEvent.calendar.allowsContentModifications else {
            throw PluginError.noAccessForEntity(.calendar, accessType: .write, source: source)
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

    func listEventsInRange(
        startDate: Double,
        endDate: Double
    ) throws -> [[String: Any]] {
        let predicate = eventStore.predicateForEvents(
            withStart: Date(timeIntervalSince1970: startDate / 1000),
            end: Date(timeIntervalSince1970: endDate / 1000), calendars: nil
        )
        let events = eventStore.events(matching: predicate)

        return events.map { event in
            var dict = [String: Any]()

            for property in [
                (event.eventIdentifier, "id"),
                (event.calendar.calendarIdentifier, "calendarId"),
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
            return dict
        }
    }

    @MainActor
    func deleteEventsById(ids: JSArray) async throws -> EventDeleteResults {
        var deleted: [String] = []
        var failed: [String] = []

        if !ids.isEmpty {
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
        }

        return EventDeleteResults(deleted: deleted, failed: failed)
    }
}
