//
//  Calendar+Calendars.swift
//  EbarooniCapacitorCalendar
//
//  Created by Aparajita on 5/16/24.
//

import EventKitUI
import Foundation

public extension CapacitorCalendar {
    @MainActor
    func selectCalendarsWithPrompt(selectionStyle: Int, displayStyle: Int) async throws -> [[String: Any]] {
        guard let bridgeViewController = bridge?.viewController,
              let selectionStyle = EKCalendarChooserSelectionStyle(rawValue: selectionStyle),
              let displayStyle = EKCalendarChooserDisplayStyle(rawValue: displayStyle) else {
            throw PluginError(.noViewController, source: #function)
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
            throw PluginError(fromError: error, source: #function)
        }
    }

    // Delegate method for EKCalendarChooser presented in selectCalendarsWithPrompt()
    func calendarChooserDidFinish(_ calendarChooser: EKCalendarChooser) {
        let selectedCalendars = calendarsToDicts(calendarChooser.selectedCalendars)
        bridge?.viewController?.dismiss(animated: true) {
            self.currentSelectCalendarsContinuation?.resume(returning: selectedCalendars)
        }
    }

    // Delegate method for EKCalendarChooser presented in selectCalendarsWithPrompt()
    func calendarChooserDidCancel(_: EKCalendarChooser) {
        bridge?.viewController?.dismiss(animated: true) {
            self.currentSelectCalendarsContinuation?.resume(returning: [])
        }
    }

    func listCalendars(_ access: EKCalendarChooserDisplayStyle) -> [[String: Any]] {
        let calendars = calendarsToDicts(Set(eventStore.calendars(for: .event)))

        if access == EKCalendarChooserDisplayStyle.writableCalendarsOnly {
            return calendars.filter { calendar in
                calendar["writeable"] as? Bool ?? false
            }
        } else {
            return calendars
        }
    }

    func getDefaultCalendar() -> [String: Any]? {
        getDefaultCalendar(for: .event, source: #function)
    }

    @MainActor
    func openCalendar(date: Double) async throws {
        try await open(URL(string: "calshow:\(date)"), errorType: .unableToOpenCalendar, source: #function)
    }

    @MainActor
    func createCalendar(title: String, color: String?) async throws -> String {
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
            throw PluginError(fromError: error, source: #function)
        }

        return newCalendar.calendarIdentifier
    }

    @MainActor
    func deleteCalendar(id: String) throws {
        if let calendar = eventStore.calendar(withIdentifier: id) {
            if calendar.allowsContentModifications {
                try eventStore.removeCalendar(calendar, commit: true)
            } else {
                throw PluginError(.noAccess, source: #function, data: "calendar/write")
            }
        } else {
            throw PluginError(.calendarNotFound, source: #function)
        }
    }
}
