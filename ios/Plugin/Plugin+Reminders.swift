//
//  Plugin+Reminders.swift
//  EbarooniCapacitorCalendar
//
//  Created by Aparajita on 5/16/24.
//

import Capacitor
import Foundation

public extension CapacitorCalendarPlugin {
    @objc func getDefaultRemindersList(_ call: CAPPluginCall) {
        tryCall(call, source: #function) {
            if try callHasAccess(call, entityType: .reminders, accessType: .read, source: #function) {
                let result = reminders.getDefaultRemindersList()
                call.resolve(["result": result ?? NSNull()])
            }
        }
    }

    @objc func getRemindersLists(_ call: CAPPluginCall) {
        tryCall(call, source: #function) {
            if try callHasAccess(call, entityType: .reminders, accessType: .read, source: #function) {
                call.resolve(["result": reminders.getRemindersLists()])
            }
        }
    }

    @objc func createReminder(_ call: CAPPluginCall) {
        guard let title = getNonEmptyString(call, "title", source: #function) else {
            return
        }

        let listId = call.getString("listId")
        let priority = call.getInt("priority")
        let isCompleted = call.getBool("isCompleted")
        let startDate = call.getDouble("startDate")
        let dueDate = call.getDouble("dueDate")
        let completionDate = call.getDouble("completionDate")
        let notes = call.getString("notes")
        let url = call.getString("url")
        let location = call.getString("location")
        var recurrence: RecurrenceParameters?

        if let recurrenceData = call.getObject("recurrence") {
            guard let frequency = recurrenceData["frequency"] as? Int else {
                PluginError.reject(call, type: .missingKey, source: #function, data: "frequency, must be provided when using recurrence")
                return
            }

            guard let interval = recurrenceData["interval"] as? Int, interval > 0 else {
                PluginError.reject(call, type: .invalidKey, source: #function, data: "interval, must be greater than 0 when using recurrence")
                return
            }

            let end = recurrenceData["end"] as? Double
            recurrence = RecurrenceParameters(frequency: frequency, interval: interval, end: end)
        }

        let reminderParams = ReminderCreationParameters(
            title: title,
            listId: listId,
            priority: priority,
            isCompleted: isCompleted,
            startDate: startDate,
            dueDate: dueDate,
            completionDate: completionDate,
            notes: notes,
            url: url,
            location: location,
            recurrence: recurrence
        )

        Task {
            await tryAsyncCall(call, source: #function) {
                if try callHasAccess(call, entityType: .reminders, accessType: .write, source: #function) {
                    let id = try await reminders.createReminder(with: reminderParams)
                    call.resolve(["result": id])
                }
            }
        }
    }

    @objc func openReminders(_ call: CAPPluginCall) {
        Task {
            await tryAsyncCall(call, source: #function) {
                try await reminders.openReminders()
            }
        }
    }
}
