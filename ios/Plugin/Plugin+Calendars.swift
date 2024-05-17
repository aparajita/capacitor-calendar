//
//  Plugin+Calendars.swift
//  EbarooniCapacitorCalendar
//
//  Created by Aparajita on 5/16/24.
//

import Capacitor
import EventKitUI
import Foundation

public extension CapacitorCalendarPlugin {
    @objc func selectCalendarsWithPrompt(_ call: CAPPluginCall) {
        guard let selectionStyle = call.getInt("selectionStyle") else {
            PluginError.reject(call, type: .missingKey, source: #function, data: "selectionStyle")
            return
        }

        guard let displayStyle = call.getInt("displayStyle") else {
            PluginError.reject(call, type: .missingKey, source: #function, data: "displayStyle")
            return
        }

        Task {
            await tryAsyncCall(call, source: #function) {
                let result = try await calendar.selectCalendarsWithPrompt(selectionStyle: selectionStyle, displayStyle: displayStyle)
                call.resolve(["result": result])
            }
        }
    }

    @objc func listCalendars(_ call: CAPPluginCall) {
        tryCall(call, source: #function) {
            if try callHasAccess(call, entityType: .calendar, accessType: .read, source: #function) {
                let accessParam = call.getInt("access", EKCalendarChooserDisplayStyle.allCalendars.rawValue)
                let access = accessParam == EKCalendarChooserDisplayStyle.allCalendars.rawValue
                    ? EKCalendarChooserDisplayStyle.allCalendars
                    : EKCalendarChooserDisplayStyle.writableCalendarsOnly
                call.resolve(["result": calendar.listCalendars(access)])
            }
        }
    }

    @objc func getDefaultCalendar(_ call: CAPPluginCall) {
        tryCall(call, source: #function) {
            if try callHasAccess(call, entityType: .calendar, accessType: .read, source: #function) {
                let defaultCalendar = calendar.getDefaultCalendar()
                call.resolve(["result": defaultCalendar ?? NSNull()])
            }
        }
    }

    @objc func createCalendar(_ call: CAPPluginCall) {
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

    @objc func deleteCalendar(_ call: CAPPluginCall) {
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

    @objc func openCalendar(_ call: CAPPluginCall) {
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
}
