import Capacitor
import EventKit
import Foundation

@objc(CapacitorCalendarPlugin)
public class CapacitorCalendarPlugin: CAPPlugin {
    let eventStore = EKEventStore()
    lazy var calendar = CapacitorCalendar(bridge: bridge, eventStore: eventStore)
    lazy var reminders = CapacitorReminders(bridge: bridge, eventStore: eventStore)
}
