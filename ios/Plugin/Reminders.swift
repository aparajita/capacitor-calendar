//
//  Reminders.swift
//  Plugin
//
//  Created by Ehsan Barooni on 15.03.24.
//  Copyright © 2024 Max Lynch. All rights reserved.
//

import EventKit
import Foundation
import UIKit

struct ReminderCreationParameters {
    let title: String
    let listId: String?
    let priority: Int?
    let isCompleted: Bool?
    let startDate: Double?
    let dueDate: Double?
    let completionDate: Double?
    let notes: String?
    let url: String?
    let location: String?
    let recurrence: RecurrenceParameters?
}

struct RecurrenceParameters {
    let frequency: Int
    let interval: Int
    let end: Double?
}

public class CapacitorReminders: CapacitorCalendarBase {
    private let recurrenceFrequencyMapping: [Int: EKRecurrenceFrequency] = [
        0: .daily,
        1: .weekly,
        2: .monthly,
        3: .yearly
    ]

    // MARK: - Permissions

    func checkAllPermissions() -> [String: String] {
        checkAllPermissions(entity: .reminder, source: #function)
    }

    func requestFullAccessToReminders() async throws -> String {
        try await requestFullAccessTo(.reminder, source: #function)
    }

    func getDefaultRemindersList() -> [String: Any]? {
        getDefaultCalendar(for: .reminder, source: #function)
    }

    func getRemindersLists() -> [[String: Any]] {
        calendarsToDicts(Set(eventStore.calendars(for: .reminder)))
    }

    @MainActor
    func createReminder(with parameters: ReminderCreationParameters) throws -> String {
        let newReminder = EKReminder(eventStore: eventStore)
        initReminder(newReminder, with: parameters)
        newReminder.title = parameters.title

        if let isCompleted = parameters.isCompleted {
            newReminder.isCompleted = isCompleted
        }

        if let notes = parameters.notes {
            newReminder.notes = notes
        }

        if let url = parameters.url {
            newReminder.url = URL(string: url)
        }

        if let location = parameters.location {
            newReminder.location = location
        }

        do {
            try eventStore.save(newReminder, commit: true)
            return newReminder.calendarItemIdentifier
        } catch {
            throw PluginError(fromError: error, source: #function)
        }
    }

    private func initReminder(_ reminder: EKReminder, with parameters: ReminderCreationParameters) {
        if let listId = parameters.listId,
           let list = eventStore.calendar(withIdentifier: listId) {
            reminder.calendar = list
        } else {
            reminder.calendar = eventStore.defaultCalendarForNewReminders()
        }

        if let priority = parameters.priority {
            reminder.priority = max(0, min(9, priority))
        }

        setReminderDateComponents(
            for: reminder,
            startDate: parameters.startDate,
            dueDate: parameters.dueDate,
            completionDate: parameters.completionDate
        )
        setReminderFrequency(for: reminder, recurrence: parameters.recurrence)
    }

    private func setReminderFrequency(for reminder: EKReminder, recurrence: RecurrenceParameters?) {
        guard let frequency = recurrence?.frequency, let interval = recurrence?.interval else { return
        }

        var endDate: EKRecurrenceEnd?

        if let end = recurrence?.end {
            endDate = EKRecurrenceEnd(end: Date(timeIntervalSince1970: end / 1000))
        }

        if let recurrenceFrequency = recurrenceFrequencyMapping[frequency] {
            reminder.recurrenceRules = [EKRecurrenceRule(
                recurrenceWith: recurrenceFrequency,
                interval: interval,
                end: endDate
            )]
        }
    }

    private func setReminderDateComponents(for reminder: EKReminder, startDate: Double?, dueDate: Double?, completionDate: Double?) {
        if let startDate = startDate {
            reminder.startDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: Date(timeIntervalSince1970: startDate / 1000)
            )
            reminder.startDateComponents?.timeZone = Calendar.current.timeZone
        }

        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: Date(timeIntervalSince1970: dueDate / 1000)
            )
            reminder.dueDateComponents?.timeZone = Calendar.current.timeZone
        }

        if let completionDate = completionDate {
            reminder.completionDate = Date(timeIntervalSince1970: completionDate / 1000)
            reminder.timeZone = Calendar.current.timeZone
        }
    }

    func openReminders() async throws {
        try await open(URL(string: "x-apple-reminderkit://"), errorType: .unableToOpenReminders, source: #function)
    }
}
