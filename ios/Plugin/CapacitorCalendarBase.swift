//
//  CapacitorCalendarBase.swift
//  EbarooniCapacitorCalendar
//
//  Created by Aparajita on 5/9/24.
//

import Capacitor
import EventKitUI
import Foundation

public class CapacitorCalendarBase: NSObject {
    internal let bridge: (any CAPBridgeProtocol)?
    internal let eventStore: EKEventStore

    init(bridge: (any CAPBridgeProtocol)?, eventStore: EKEventStore) {
        self.bridge = bridge
        self.eventStore = eventStore
    }

    internal func checkAllPermissions(entity: EKEntityType, source: String) -> [String: String] {
        let read: PermissionState
        let write: PermissionState
        let status = EKEventStore.authorizationStatus(for: entity)

        switch status {
        case .authorized, .fullAccess:
            read = PermissionState.granted
            write = PermissionState.granted

        case .denied, .restricted:
            read = PermissionState.denied
            write = PermissionState.denied

        case .writeOnly:
            read = PermissionState.prompt
            write = entity == .event ? PermissionState.granted : PermissionState.prompt

        case .notDetermined:
            read = PermissionState.prompt
            write = PermissionState.prompt

        @unknown default:
            read = PermissionState.denied
            write = PermissionState.denied
        }

        let entityName = entity == .event ? "Calendar" : "Reminders"

        return [
            "read\(entityName)": read.rawValue,
            "write\(entityName)": write.rawValue
        ]
    }

    @MainActor
    internal func requestFullAccessTo(_ entity: EKEntityType, source: String) async throws -> String {
        do {
            var granted: Bool

            if #available(iOS 17.0, *) {
                if entity == .event {
                    granted = try await eventStore.requestFullAccessToEvents()
                } else {
                    granted = try await eventStore.requestFullAccessToReminders()
                }
            } else {
                granted = try await eventStore.requestAccess(to: entity)
            }

            return granted ? PermissionState.granted.rawValue : PermissionState.denied.rawValue
        } catch {
            throw CapacitorCalendarError(fromError: error, source: source)
        }
    }

    internal func getDefaultCalendar(for entity: EKEntityType, source: String) -> [String: Any]? {
        if let defaultCalendar = entity == .event ? eventStore.defaultCalendarForNewEvents : eventStore.defaultCalendarForNewReminders() {
            return [
                "id": defaultCalendar.calendarIdentifier,
                "title": defaultCalendar.title,
                "writeable": defaultCalendar.allowsContentModifications
            ]
        } else {
            return nil
        }
    }

    internal func calendarsToDicts(_ calendars: Set<EKCalendar>) -> [[String: Any]] {
        var result: [[String: Any]] = []

        for calendar in calendars {
            let calendarDict: [String: Any] = [
                "id": calendar.calendarIdentifier,
                "title": calendar.title,
                "writeable": calendar.allowsContentModifications
            ]
            result.append(calendarDict)
        }

        return result
    }

    @MainActor
    internal func open(_ url: URL?, errorType: CapacitorCalendarError.ErrorType, source: String) async throws {
        var success = false

        if let url = url {
            success = await UIApplication.shared.open(url, options: [:])
        }

        if !success {
            throw CapacitorCalendarError(errorType, source: source)
        }
    }
}
