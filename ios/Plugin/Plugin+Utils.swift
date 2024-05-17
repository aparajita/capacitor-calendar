//
//  Plugin+Utils.swift
//  EbarooniCapacitorCalendar
//
//  Created by Aparajita on 5/16/24.
//

import Capacitor
import Foundation

extension CapacitorCalendarPlugin {
    func tryCall(_ call: CAPPluginCall, source: String, _ block: () throws -> Void) {
        do {
            try block()
        } catch {
            PluginError.reject(call, error: error, source: source)
        }
    }

    func tryAsyncCall(_ call: CAPPluginCall, source: String, _ block: () async throws -> Void) async {
        do {
            try await block()
        } catch {
            PluginError.reject(call, error: error, source: source)
        }
    }

    func getNonEmptyString(_ call: CAPPluginCall, _ param: String, source: String) -> String? {
        guard let value = call.getString(param),
              !value.isEmpty else {
            PluginError.reject(call, type: .missingKey, source: source, data: param)
            return nil
        }

        return value
    }
}
