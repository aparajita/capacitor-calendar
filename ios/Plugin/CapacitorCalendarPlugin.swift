import Foundation
import EventKitUI
import EventKit
import Capacitor

@objc(CapacitorCalendarPlugin)
public class CapacitorCalendarPlugin: CAPPlugin {
    private let eventStore = EKEventStore()
    private lazy var calendar = CapacitorCalendar(bridge: self.bridge, eventStore: self.eventStore)
    private lazy var reminders = CapacitorReminders(bridge: self.bridge, eventStore: self.eventStore)

    // MARK: - Utils

    private func tryCall(_ call: CAPPluginCall, source: String, _ op: () throws -> Void) {
        do {
            try op()
        } catch {
            CapacitorCalendarError.reject(call, error: error, source: source)
        }
    }

    private func tryAsyncCall(_ call: CAPPluginCall, source: String, _ op: () async throws -> Void) async {
        do {
            try await op()
        } catch {
            CapacitorCalendarError.reject(call, error: error, source: source)
        }
    }

    private func getNonEmptyString(_ call: CAPPluginCall, _ param: String, source: String) -> String? {
        guard let value = call.getString(param),
              !value.isEmpty else {
            CapacitorCalendarError.reject(call, type: .missingKey, source: source, data: param)
            return nil
        }

        return value
    }

    // MARK: - Permissions

    private func callHasAccess(_ call: CAPPluginCall, entityType: EntityType, accessType: AccessType, source: String) throws -> Bool {
        let eventTypeName = String(describing: entityType)
        let accessTypeName = String(describing: accessType)
        let permission = try doPermissionCheck(for: "\(accessTypeName)\(eventTypeName.capitalized)")

        if permission == "granted" {
            return true
        } else {
            CapacitorCalendarError.rejectWithNoAccess(call, entityType: entityType, accessType: accessType, source: source)
            return false
        }
    }

    private func doPermissionCheck(for alias: String) throws -> String {
        let permissionsState: [String: String]

        switch alias {
        case "readCalendar":
            permissionsState = calendar.checkAllPermissions()

        case "writeCalendar":
            permissionsState = calendar.checkAllPermissions()

        case "readReminders":
            permissionsState = reminders.checkAllPermissions()

        case "writeReminders":
            permissionsState = reminders.checkAllPermissions()

        default:
            throw CapacitorCalendarError(.invalidKey, source: #function, data: alias)
        }

        guard let permissionResult = permissionsState[alias] else {
            throw CapacitorCalendarError(.internalError, source: #function, data: "Invalid permission state")
        }

        return permissionResult
    }

    @objc public func checkPermission(_ call: CAPPluginCall) {
        guard let alias = getNonEmptyString(call, "alias", source: #function) else {
            return
        }

        tryCall(call, source: #function) {
            try call.resolve(["result": self.doPermissionCheck(for: alias)])
        }
    }

    @objc public func checkAllPermissions(_ call: CAPPluginCall) {
        let calendarPermissionsState = calendar.checkAllPermissions()
        let remindersPermissionsState = reminders.checkAllPermissions()
        call.resolve(calendarPermissionsState.merging(remindersPermissionsState) { (_, new) in new })
    }

    @objc public func requestWriteOnlyCalendarAccess(_ call: CAPPluginCall) {
        Task {
            await tryAsyncCall(call, source: #function) {
                let result = try await calendar.requestWriteAccessToEvents()
                call.resolve(result)
            }
        }
    }

    @objc public func requestFullCalendarAccess(_ call: CAPPluginCall) {
        Task {
            await tryAsyncCall(call, source: #function) {
                let result = try await calendar.requestFullAccessToEvents()
                call.resolve(["result": result])
            }
        }
    }

    @objc public func requestFullRemindersAccess(_ call: CAPPluginCall) {
        Task {
            await tryAsyncCall(call, source: #function) {
                let result = try await reminders.requestFullAccessToReminders()
                call.resolve(["result": result])
            }
        }
    }

    // Deprecated, use methods above instead.
    @objc public func requestPermission(_ call: CAPPluginCall) {
        guard let alias = getNonEmptyString(call, "alias", source: #function) else {
            return
        }

        Task {
            await tryAsyncCall(call, source: #function) {
                switch alias {
                case "writeCalendar":
                    let result = try await calendar.requestWriteAccessToEvents()
                    call.resolve(result)

                case "readCalendar":
                    let result = try await calendar.requestFullAccessToEvents()
                    call.resolve(["result": result])

                case "writeReminders":
                    let result = try await reminders.requestFullAccessToReminders()
                    call.resolve(["result": result])

                case "readReminders":
                    let result = try await reminders.requestFullAccessToReminders()
                    call.resolve(["result": result])

                default:
                    CapacitorCalendarError.reject(call, type: .invalidKey, source: #function, data: alias)
                    return
                }
            }
        }
    }

    @objc public func requestAllPermissions(_ call: CAPPluginCall) {
        Task {
            await tryAsyncCall(call, source: #function) {
                let calendarResult = try await calendar.requestFullAccessToEvents()
                let remindersResult = try await reminders.requestFullAccessToReminders()
                var result: [String: String] = [
                    "readCalendar": PermissionState.denied.rawValue,
                    "writeCalendar": PermissionState.denied.rawValue,
                    "readReminders": PermissionState.denied.rawValue,
                    "writeReminders": PermissionState.denied.rawValue
                ]

                if calendarResult == PermissionState.granted.rawValue {
                    result["readCalendar"] = PermissionState.granted.rawValue
                    result["writeCalendar"] = PermissionState.granted.rawValue
                }

                if remindersResult == PermissionState.granted.rawValue {
                    result["readReminders"] = PermissionState.granted.rawValue
                    result["writeReminders"] = PermissionState.granted.rawValue
                }

                call.resolve(result)
            }
        }
    }

    // MARK: - Calendars

    @objc public func selectCalendarsWithPrompt(_ call: CAPPluginCall) {
        guard let selectionStyle = call.getInt("selectionStyle") else {
            CapacitorCalendarError.reject(call, type: .missingKey, source: #function, data: "selectionStyle")
            return
        }

        guard let displayStyle = call.getInt("displayStyle") else {
            CapacitorCalendarError.reject(call, type: .missingKey, source: #function, data: "displayStyle")
            return
        }

        Task {
            await tryAsyncCall(call, source: #function) {
                let result = try await calendar.selectCalendarsWithPrompt(selectionStyle: selectionStyle, displayStyle: displayStyle)
                call.resolve(["result": result])
            }
        }
    }

    @objc public func listCalendars(_ call: CAPPluginCall) {
        tryCall(call, source: #function) {
            if try callHasAccess(call, entityType: .calendar, accessType: .read, source: #function) {
                let access = call.getInt("access", EKCalendarChooserDisplayStyle.allCalendars.rawValue) == EKCalendarChooserDisplayStyle.allCalendars.rawValue ? EKCalendarChooserDisplayStyle.allCalendars : EKCalendarChooserDisplayStyle.writableCalendarsOnly
                call.resolve(["result": calendar.listCalendars(access)])
            }
        }
    }

    @objc public func getDefaultCalendar(_ call: CAPPluginCall) {
        tryCall(call, source: #function) {
            if try callHasAccess(call, entityType: .calendar, accessType: .read, source: #function) {
                let defaultCalendar = calendar.getDefaultCalendar()
                call.resolve(["result": defaultCalendar ?? NSNull()])
            }
        }
    }

    @objc public func createCalendar(_ call: CAPPluginCall) {
        guard let title = getNonEmptyString(call, "title", source: #function) else {
            return
        }

        let color = call.getString("color")

        Task {
            await tryAsyncCall(call, source: #function) {
                if try callHasAccess(call, entityType: .calendar, accessType: .write, source: #function) {
                    let id = try await calendar.createCalendar(title: title, color: color)
                    call.resolve(["result": id])
                }
            }
        }
    }

    @objc public func deleteCalendar(_ call: CAPPluginCall) {
        guard let id = getNonEmptyString(call, "id", source: #function) else {
            return
        }

        Task {
            await tryAsyncCall(call, source: #function) {
                if try callHasAccess(call, entityType: .calendar, accessType: .write, source: #function) {
                    try await calendar.deleteCalendar(id: id)
                    call.resolve()
                }
            }
        }
    }

    @objc public func openCalendar(_ call: CAPPluginCall) {
        let interval: Double

        if let date = call.getDouble("date") {
            interval = Date(timeIntervalSince1970: date / 1000).timeIntervalSinceReferenceDate
        } else {
            interval = Date.timeIntervalSinceReferenceDate
        }

        Task {
            await tryAsyncCall(call, source: #function) {
                try await calendar.openCalendar(date: interval)
            }
        }
    }

    // MARK: - Events

    private func doCreateEvent(_ call: CAPPluginCall, prompt: Bool, source: String) {
        Task {
            await tryAsyncCall(call, source: source) {
                if try !callHasAccess(call, entityType: .calendar, accessType: .write, source: source) {
                    return
                }

                let title = call.getString("title", "New event")
                let location = call.getString("location")
                let startDate = call.getDouble("startDate")
                let endDate = call.getDouble("endDate")
                let isAllDay = call.getBool("isAllDay")
                let calendarId = call.getString("calendarId")
                let alertOffsetInMinutes = call.getDouble("alertOffsetInMinutes")

                let eventParameters = EventCreationParameters(
                    title: title,
                    calendarId: calendarId,
                    location: location,
                    startDate: startDate,
                    endDate: endDate,
                    isAllDay: isAllDay,
                    alertOffsetInMinutes: alertOffsetInMinutes
                )

                if prompt {
                    let result = try await calendar.createEventWithPrompt(with: eventParameters)
                    call.resolve(["result": result])
                } else {
                    let result = try await calendar.createEvent(with: eventParameters)
                    call.resolve(["result": result])
                }
            }
        }

    }

    @objc public func createEvent(_ call: CAPPluginCall) {
        if getNonEmptyString(call, "title", source: #function) == nil {
            return
        }

        doCreateEvent(call, prompt: false, source: #function)
    }

    @objc public func createEventWithPrompt(_ call: CAPPluginCall) {
        doCreateEvent(call, prompt: true, source: #function)
    }

    @objc public func listEventsInRange(_ call: CAPPluginCall) {
        guard let startDate = call.getDouble("startDate") else {
            CapacitorCalendarError.reject(call, type: .missingKey, source: #function, data: "startDate")
            return
        }

        guard let endDate = call.getDouble("endDate") else {
            CapacitorCalendarError.reject(call, type: .missingKey, source: #function, data: "endDate")
            return
        }

        tryCall(call, source: #function) {
            if try callHasAccess(call, entityType: .calendar, accessType: .read, source: #function) {
                try call.resolve(["result": calendar.listEventsInRange(startDate: startDate, endDate: endDate)])
            }
        }
    }

    @objc public func deleteEventsById(_ call: CAPPluginCall) {
        guard let eventIds = call.getArray("ids") else {
            CapacitorCalendarError.reject(call, type: .missingKey, source: #function, data: "ids")
            return
        }

        Task {
            await tryAsyncCall(call, source: #function) {
                if try callHasAccess(call, entityType: .calendar, accessType: .write, source: #function) {
                    let deleteResult = try await calendar.deleteEventsById(ids: eventIds)
                    call.resolve([
                        "result": [
                            "deleted": deleteResult.deleted,
                            "failed": deleteResult.failed
                        ]
                    ])
                }
            }
        }
    }

    // MARK: - Reminders

    @objc public func getDefaultRemindersList(_ call: CAPPluginCall) {
        tryCall(call, source: #function) {
            if try callHasAccess(call, entityType: .reminders, accessType: .read, source: #function) {
                let result = reminders.getDefaultRemindersList()
                call.resolve(["result": result ?? NSNull()])
            }
        }
    }

    @objc public func getRemindersLists(_ call: CAPPluginCall) {
        tryCall(call, source: #function) {
            if try callHasAccess(call, entityType: .reminders, accessType: .read, source: #function) {
                call.resolve(["result": reminders.getRemindersLists()])
            }
        }
    }

    @objc public func createReminder (_ call: CAPPluginCall) {
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
                CapacitorCalendarError.reject(call, type: .missingKey, source: #function, data: "frequency, must be provided when using recurrence")
                return
            }

            guard let interval = recurrenceData["interval"] as? Int, interval > 0 else {
                CapacitorCalendarError.reject(call, type: .invalidKey, source: #function, data: "interval, must be greater than 0 when using recurrence")
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

    @objc public func openReminders(_ call: CAPPluginCall) {
        Task {
            await tryAsyncCall(call, source: #function) {
                try await reminders.openReminders()
            }
        }
    }
}
