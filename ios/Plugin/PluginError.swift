//
//  PluginError.swift
//  EbarooniCapacitorCalendar
//
//  Created by Aparajita on 5/8/24.
//

import Capacitor
import EventKit
import Foundation

public class PluginError: Error {
    enum ErrorType: String {
        case missingKey
        case invalidKey
        case noAccess
        case calendarNotFound
        case noDefaultCalendar
        case unableToOpenCalendar
        case unableToOpenReminders
        case noViewController
        case osError
        case unimplemented
        case internalError
        case unknownError
    }

    private static let errorMessages: [ErrorType: String] = [
        .missingKey: "Empty or missing key",
        .invalidKey: "Invalid value for key",
        .noAccess: "Access has not been granted",
        .calendarNotFound: "Calendar with the given id not found",
        .noDefaultCalendar: "No default calendar is available",
        .unableToOpenCalendar: "The calendar app could not be opened",
        .unableToOpenReminders: "The reminders app could not be opened",
        .noViewController: "View controller could not be created",
        .osError: "An iOS error has occurred",
        .unimplemented: "Not implemented on iOS",
        .unknownError: "An unknown error occurred"
    ]

    var message: String = ""
    var type: String = ""

    convenience init(fromError: Error, source: String) {
        self.init(.osError, source: source, data: fromError.localizedDescription)
    }

    init(_ type: ErrorType, source: String, data: String? = nil) {
        self.type = type.rawValue

        if let msg = PluginError.errorMessages[type] {
            message = msg

            switch type {
            case .missingKey, .invalidKey:
                if let data = data {
                    message = "\(msg) \(data)"
                }

            case .noAccess:
                if let data = data {
                    message = "\(msg) (\(data))"
                }

            case .internalError, .osError, .unknownError:
                if let data = data {
                    message = "\(msg): \(data)"
                }

            default:
                break
            }
        } else {
            // We know this key exists
            message = PluginError.errorMessages[.unknownError] ?? "Unknown error"
        }

        message = "[CapacitorCalendar.\(source)] \(message)"
    }

    func reject(_ call: CAPPluginCall) {
        call.reject(message, nil, nil, ["type": type])
    }

    static func reject(_ call: CAPPluginCall, error: Error, source: String) {
        if let error = error as? PluginError {
            error.reject(call)
        } else {
            reject(call, type: .osError, source: source, data: error.localizedDescription)
        }
    }

    static func reject(_ call: CAPPluginCall, type: ErrorType, source: String, data: String? = nil) {
        PluginError(type, source: source, data: data).reject(call)
    }

    static func noAccessForEntity(_ entityType: EntityType, accessType: AccessType, source: String) -> PluginError {
        PluginError(.noAccess, source: source, data: "\(entityType)/\(accessType)")
    }

    static func rejectWithNoAccess(_ call: CAPPluginCall, entityType: EntityType, accessType: AccessType, source: String) {
        noAccessForEntity(entityType, accessType: accessType, source: source).reject(call)
    }

    static func unimplemented(_ call: CAPPluginCall, source: String) {
        PluginError.reject(call, type: .unimplemented, source: source)
    }
}
