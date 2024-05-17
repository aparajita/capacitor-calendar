//
//  Plugin+Events.swift
//  EbarooniCapacitorCalendar
//
//  Created by Aparajita on 5/16/24.
//

import Capacitor
import Foundation

public extension CapacitorCalendarPlugin {
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

    @objc func createEvent(_ call: CAPPluginCall) {
        if getNonEmptyString(call, "title", source: #function) == nil {
            return
        }

        doCreateEvent(call, prompt: false, source: #function)
    }

    @objc func createEventWithPrompt(_ call: CAPPluginCall) {
        doCreateEvent(call, prompt: true, source: #function)
    }

    @objc func listEventsInRange(_ call: CAPPluginCall) {
        guard let startDate = call.getDouble("startDate") else {
            PluginError.reject(call, type: .missingKey, source: #function, data: "startDate")
            return
        }

        guard let endDate = call.getDouble("endDate") else {
            PluginError.reject(call, type: .missingKey, source: #function, data: "endDate")
            return
        }

        tryCall(call, source: #function) {
            if try callHasAccess(call, entityType: .calendar, accessType: .read, source: #function) {
                try call.resolve(["result": calendar.listEventsInRange(startDate: startDate, endDate: endDate)])
            }
        }
    }

    @objc func deleteEventsById(_ call: CAPPluginCall) {
        guard let eventIds = call.getArray("ids") else {
            PluginError.reject(call, type: .missingKey, source: #function, data: "ids")
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
}
