//
//  Plugin+Permissions.swift
//  EbarooniCapacitorCalendar
//
//  Created by Aparajita on 5/16/24.
//

import Capacitor
import Foundation

public extension CapacitorCalendarPlugin {
    internal func callHasAccess(_ call: CAPPluginCall, entityType: EntityType, accessType: AccessType, source: String) throws -> Bool {
        let eventTypeName = String(describing: entityType)
        let accessTypeName = String(describing: accessType)
        let permission = try doPermissionCheck(for: "\(accessTypeName)\(eventTypeName.capitalized)", source: source)

        if permission == "granted" {
            return true
        } else {
            PluginError.rejectWithNoAccess(call, entityType: entityType, accessType: accessType, source: source)
            return false
        }
    }

    internal func doPermissionCheck(for alias: String, source: String) throws -> String {
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
            throw PluginError(.invalidKey, source: #function, data: alias)
        }

        guard let permissionResult = permissionsState[alias] else {
            throw PluginError(.internalError, source: source, data: "Invalid permission state")
        }

        return permissionResult
    }

    @objc func checkPermission(_ call: CAPPluginCall) {
        guard let alias = getNonEmptyString(call, "alias", source: #function) else {
            return
        }

        tryCall(call, source: #function) {
            try call.resolve(["result": self.doPermissionCheck(for: alias, source: #function)])
        }
    }

    @objc func checkAllPermissions(_ call: CAPPluginCall) {
        let calendarPermissionsState = calendar.checkAllPermissions()
        let remindersPermissionsState = reminders.checkAllPermissions()
        call.resolve(calendarPermissionsState.merging(remindersPermissionsState) { _, new in new })
    }

    @objc func requestReadOnlyCalendarAccess(_ call: CAPPluginCall) {
        PluginError.unimplemented(call, source: #function)
    }

    @objc func requestWriteOnlyCalendarAccess(_ call: CAPPluginCall) {
        Task {
            await tryAsyncCall(call, source: #function) {
                let result = try await calendar.requestWriteAccessToEvents()
                call.resolve(result)
            }
        }
    }

    @objc func requestFullCalendarAccess(_ call: CAPPluginCall) {
        Task {
            await tryAsyncCall(call, source: #function) {
                let result = try await calendar.requestFullAccessToEvents()
                call.resolve(["result": result])
            }
        }
    }

    @objc func requestFullRemindersAccess(_ call: CAPPluginCall) {
        Task {
            await tryAsyncCall(call, source: #function) {
                let result = try await reminders.requestFullAccessToReminders()
                call.resolve(["result": result])
            }
        }
    }

    // Deprecated, use methods above instead.
    @objc func requestPermission(_ call: CAPPluginCall) {
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
                    PluginError.reject(call, type: .invalidKey, source: #function, data: alias)
                    return
                }
            }
        }
    }

    @objc func requestAllPermissions(_ call: CAPPluginCall) {
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
}
