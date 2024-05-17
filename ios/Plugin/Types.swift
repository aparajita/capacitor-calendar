//
//  Types.swift
//  EbarooniCapacitorCalendar
//
//  Created by Aparajita on 5/14/24.
//

enum PermissionState: String {
    case granted
    case denied
    case prompt
    case promptWithRationale = "prompt-with-rationale"
}

enum EntityType {
    case calendar
    case reminders
}

enum AccessType {
    case read
    case write
}
