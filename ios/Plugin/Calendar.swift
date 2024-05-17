import Capacitor
import EventKitUI
import Foundation

public class CapacitorCalendar: CapacitorCalendarBase, EKEventEditViewDelegate, EKCalendarChooserDelegate {
    var currentCreateEventContinuation: CheckedContinuation<[String], any Error>?
    var currentSelectCalendarsContinuation: CheckedContinuation<[[String: Any]], any Error>?

    public func checkAllPermissions() -> [String: String] {
        checkAllPermissions(entity: .event, source: #function)
    }

    @MainActor
    public func requestWriteAccessToEvents() async throws -> [String: String] {
        do {
            var granted: Bool

            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestWriteOnlyAccessToEvents()
            } else {
                granted = try await eventStore.requestAccess(to: .event)
            }

            let permisson = granted ? PermissionState.granted.rawValue : PermissionState.denied.rawValue
            return ["result": permisson]
        } catch {
            throw PluginError(fromError: error, source: #function)
        }
    }

    public func requestFullAccessToEvents() async throws -> String {
        try await requestFullAccessTo(.event, source: #function)
    }
}
