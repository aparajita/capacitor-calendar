## API

<docgen-index>

* [`checkPermission(...)`](#checkpermission)
* [`checkAllPermissions()`](#checkallpermissions)
* [`requestReadOnlyCalendarAccess()`](#requestreadonlycalendaraccess)
* [`requestWriteOnlyCalendarAccess()`](#requestwriteonlycalendaraccess)
* [`requestFullCalendarAccess()`](#requestfullcalendaraccess)
* [`requestFullRemindersAccess()`](#requestfullremindersaccess)
* [`requestAllPermissions()`](#requestallpermissions)
* [`requestPermission(...)`](#requestpermission)
* [`listCalendars(...)`](#listcalendars)
* [`getDefaultCalendar()`](#getdefaultcalendar)
* [`selectCalendarsWithPrompt(...)`](#selectcalendarswithprompt)
* [`createCalendar(...)`](#createcalendar)
* [`deleteCalendar(...)`](#deletecalendar)
* [`openCalendar(...)`](#opencalendar)
* [`createEvent(...)`](#createevent)
* [`createEventWithPrompt(...)`](#createeventwithprompt)
* [`listEventsInRange(...)`](#listeventsinrange)
* [`deleteEventsById(...)`](#deleteeventsbyid)
* [`createReminder(...)`](#createreminder)
* [`getDefaultRemindersList()`](#getdefaultreminderslist)
* [`getRemindersLists()`](#getreminderslists)
* [`openReminders()`](#openreminders)
* [Interfaces](#interfaces)
* [Type Aliases](#type-aliases)
* [Enums](#enums)

</docgen-index>

<docgen-api>
<!--Update the source file JSDoc comments and rerun docgen to update the docs below-->

### checkPermission(...)

```typescript
checkPermission(options: { alias: PluginPermission; }) => Promise<{ result: PermissionState; }>
```

Checks the current authorization status of a specific permission.

| Param         | Type                                                                      |
| ------------- | ------------------------------------------------------------------------- |
| **`options`** | <code>{ alias: <a href="#pluginpermission">PluginPermission</a>; }</code> |

**Returns:** <code>Promise&lt;{ result: <a href="#permissionstate">PermissionState</a>; }&gt;</code>

--------------------


### checkAllPermissions()

```typescript
checkAllPermissions() => Promise<PluginPermissionsMap>
```

Checks the current authorization status of all the required permissions for the plugin.

**Returns:** <code>Promise&lt;<a href="#pluginpermissionsmap">PluginPermissionsMap</a>&gt;</code>

**Since:** 6.4.0

--------------------


### requestReadOnlyCalendarAccess()

```typescript
requestReadOnlyCalendarAccess() => Promise<{ result: Access; }>
```

[Android only] Requests read-only access to the calendar. If access has
not already been granted or denied, the user will be prompted to grant it.

**Returns:** <code>Promise&lt;{ result: <a href="#access">Access</a>; }&gt;</code>

**Since:** 6.4.0

--------------------


### requestWriteOnlyCalendarAccess()

```typescript
requestWriteOnlyCalendarAccess() => Promise<{ result: Access; }>
```

Requests write-only access to the calendar. If access has not already
been granted or denied, the user will be prompted to grant it.

Note: On iOS &lt; 17, requesting write-only access is the same as read/write.

**Returns:** <code>Promise&lt;{ result: <a href="#access">Access</a>; }&gt;</code>

**Since:** 6.4.0

--------------------


### requestFullCalendarAccess()

```typescript
requestFullCalendarAccess() => Promise<{ result: Access; }>
```

Requests read/write access to the calendar. If access has not already
been granted or denied, the user will be prompted to grant it.

**Returns:** <code>Promise&lt;{ result: <a href="#access">Access</a>; }&gt;</code>

**Since:** 6.4.0

--------------------


### requestFullRemindersAccess()

```typescript
requestFullRemindersAccess() => Promise<{ result: Access; }>
```

[iOS only] Requests read/write access to reminders. If access has not already
been granted or denied, the user will be prompted to grant it.

**Returns:** <code>Promise&lt;{ result: <a href="#access">Access</a>; }&gt;</code>

**Since:** 6.4.0

--------------------


### requestAllPermissions()

```typescript
requestAllPermissions() => Promise<PluginPermissionsMap>
```

Requests authorization to all required permissions for the plugin.
If any of the permissions have not yet been granted or denied,
the user will be prompted to grant them.

**Returns:** <code>Promise&lt;<a href="#pluginpermissionsmap">PluginPermissionsMap</a>&gt;</code>

--------------------


### requestPermission(...)

```typescript
requestPermission(options: { alias: PluginPermission; }) => Promise<{ result: PermissionState; }>
```

Requests authorization to a specific permission, if not already granted.
If the permission is already granted, it will directly return the status.

| Param         | Type                                                                      |
| ------------- | ------------------------------------------------------------------------- |
| **`options`** | <code>{ alias: <a href="#pluginpermission">PluginPermission</a>; }</code> |

**Returns:** <code>Promise&lt;{ result: <a href="#permissionstate">PermissionState</a>; }&gt;</code>

--------------------


### listCalendars(...)

```typescript
listCalendars(options?: { access: CalendarChooserDisplayStyle; } | undefined) => Promise<{ result: Calendar[]; }>
```

Retrieves a list of calendars available on the device.

| Param         | Type                                                                                             | Description                                                                       |
| ------------- | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| **`options`** | <code>{ access: <a href="#calendarchooserdisplaystyle">CalendarChooserDisplayStyle</a>; }</code> | Options for customizing the display and selection styles of the calendar chooser. |

**Returns:** <code>Promise&lt;{ result: Calendar[]; }&gt;</code>

--------------------


### getDefaultCalendar()

```typescript
getDefaultCalendar() => Promise<{ result: Calendar | null; }>
```

Retrieves the default calendar on the device.

**Returns:** <code>Promise&lt;{ result: <a href="#calendar">Calendar</a> | null; }&gt;</code>

--------------------


### selectCalendarsWithPrompt(...)

```typescript
selectCalendarsWithPrompt(options: { displayStyle: CalendarChooserDisplayStyle; selectionStyle: CalendarChooserSelectionStyle; }) => Promise<{ result: Calendar[]; }>
```

[iOS only] Presents a prompt to the user to select calendars.

| Param         | Type                                                                                                                                                                                               | Description                                                                       |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| **`options`** | <code>{ displayStyle: <a href="#calendarchooserdisplaystyle">CalendarChooserDisplayStyle</a>; selectionStyle: <a href="#calendarchooserselectionstyle">CalendarChooserSelectionStyle</a>; }</code> | Options for customizing the display and selection styles of the calendar chooser. |

**Returns:** <code>Promise&lt;{ result: Calendar[]; }&gt;</code>

**Since:** 0.2.0

--------------------


### createCalendar(...)

```typescript
createCalendar(options: { title: string; color?: string; }) => Promise<{ result: string; }>
```

[iOS only] Creates a calendar.

| Param         | Type                                            | Description                      |
| ------------- | ----------------------------------------------- | -------------------------------- |
| **`options`** | <code>{ title: string; color?: string; }</code> | Options for creating a calendar. |

**Returns:** <code>Promise&lt;{ result: string; }&gt;</code>

**Since:** 5.2.0

--------------------


### deleteCalendar(...)

```typescript
deleteCalendar(options: { id: string; }) => Promise<void>
```

[iOS only] Deletes a calendar by id.

| Param         | Type                         | Description                      |
| ------------- | ---------------------------- | -------------------------------- |
| **`options`** | <code>{ id: string; }</code> | Options for deleting a calendar. |

**Since:** 5.2.0

--------------------


### openCalendar(...)

```typescript
openCalendar(options: { date?: number; }) => Promise<void>
```

Opens the native calendar app, which will suspend your app.
The calendar will open to today's date if no date is provided.

| Param         | Type                            | Description                       |
| ------------- | ------------------------------- | --------------------------------- |
| **`options`** | <code>{ date?: number; }</code> | Options for opening the calendar. |

--------------------


### createEvent(...)

```typescript
createEvent(options: { title: string; calendarId?: string; location?: string; startDate?: number; endDate?: number; isAllDay?: boolean; alertOffsetInMinutes?: number; }) => Promise<{ result: string; }>
```

Creates an event with the provided options.

| Param         | Type                                                                                                                                                             | Description                     |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| **`options`** | <code>{ title: string; calendarId?: string; location?: string; startDate?: number; endDate?: number; isAllDay?: boolean; alertOffsetInMinutes?: number; }</code> | Options for creating the event. |

**Returns:** <code>Promise&lt;{ result: string; }&gt;</code>

--------------------


### createEventWithPrompt(...)

```typescript
createEventWithPrompt(options: { title: string; calendarId?: string; location?: string; startDate?: number; endDate?: number; isAllDay?: boolean; alertOffsetInMinutes?: number; }) => Promise<{ result: string[]; }>
```

Creates an event in the calendar by using the native calendar.
On iOS opens a native sheet and on Android opens an intent.

| Param         | Type                                                                                                                                                             | Description                     |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------- |
| **`options`** | <code>{ title: string; calendarId?: string; location?: string; startDate?: number; endDate?: number; isAllDay?: boolean; alertOffsetInMinutes?: number; }</code> | Options for creating the event. |

**Returns:** <code>Promise&lt;{ result: string[]; }&gt;</code>

**Since:** 0.1.0

--------------------


### listEventsInRange(...)

```typescript
listEventsInRange(options: { startDate: number; endDate: number; }) => Promise<{ result: CalendarEvent[]; }>
```

Retrieves a list of calendar events present in the given date range.

| Param         | Type                                                 | Description                          |
| ------------- | ---------------------------------------------------- | ------------------------------------ |
| **`options`** | <code>{ startDate: number; endDate: number; }</code> | Options for defining the date range. |

**Returns:** <code>Promise&lt;{ result: CalendarEvent[]; }&gt;</code>

**Since:** 0.10.0

--------------------


### deleteEventsById(...)

```typescript
deleteEventsById(options: { ids: string[]; }) => Promise<{ result: { deleted: string[]; failed: string[]; }; }>
```

Deletes events from the calendar given their IDs.

| Param         | Type                            | Description                     |
| ------------- | ------------------------------- | ------------------------------- |
| **`options`** | <code>{ ids: string[]; }</code> | Options for defining event IDs. |

**Returns:** <code>Promise&lt;{ result: { deleted: string[]; failed: string[]; }; }&gt;</code>

**Since:** 0.11.0

--------------------


### createReminder(...)

```typescript
createReminder(options: { title: string; listId?: string; priority?: number; isCompleted?: boolean; startDate?: number; dueDate?: number; completionDate?: number; notes?: string; url?: string; location?: string; recurrence?: ReminderRecurrenceRule; }) => Promise<{ result: string; }>
```

[iOS only] Creates a reminder with the provided options.

| Param         | Type                                                                                                                                                                                                                                                                                  | Description                        |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------- |
| **`options`** | <code>{ title: string; listId?: string; priority?: number; isCompleted?: boolean; startDate?: number; dueDate?: number; completionDate?: number; notes?: string; url?: string; location?: string; recurrence?: <a href="#reminderrecurrencerule">ReminderRecurrenceRule</a>; }</code> | Options for creating the reminder. |

**Returns:** <code>Promise&lt;{ result: string; }&gt;</code>

**Since:** 0.5.0

--------------------


### getDefaultRemindersList()

```typescript
getDefaultRemindersList() => Promise<{ result: RemindersList; }>
```

[iOS only] Retrieves the default reminders list on the device.

**Returns:** <code>Promise&lt;{ result: <a href="#reminderslist">RemindersList</a>; }&gt;</code>

--------------------


### getRemindersLists()

```typescript
getRemindersLists() => Promise<{ result: RemindersList[]; }>
```

[iOS only] Retrieves all available reminders lists on the device.

**Returns:** <code>Promise&lt;{ result: RemindersList[]; }&gt;</code>

--------------------


### openReminders()

```typescript
openReminders() => Promise<void>
```

[iOS only] Opens the native calendar app, which will suspend your app.
The calendar will open to today's date if no date is provided.

--------------------


### Interfaces


#### PluginPermissionsMap


#### Calendar

Represents a calendar object.

| Prop           | Type                 |
| -------------- | -------------------- |
| **`id`**       | <code>string</code>  |
| **`title`**    | <code>string</code>  |
| **`writable`** | <code>boolean</code> |


#### CalendarEvent

Represents an event in the calendar.

| Prop                   | Type                 |
| ---------------------- | -------------------- |
| **`id`**               | <code>string</code>  |
| **`title`**            | <code>string</code>  |
| **`location`**         | <code>string</code>  |
| **`eventColor`**       | <code>string</code>  |
| **`organizer`**        | <code>string</code>  |
| **`description`**      | <code>string</code>  |
| **`startDate`**        | <code>number</code>  |
| **`endDate`**          | <code>number</code>  |
| **`eventTimezone`**    | <code>string</code>  |
| **`eventEndTimezone`** | <code>string</code>  |
| **`duration`**         | <code>string</code>  |
| **`isAllDay`**         | <code>boolean</code> |
| **`calendarId`**       | <code>string</code>  |


#### ReminderRecurrenceRule

| Prop            | Type                                                                                | Description                                                                                             |
| --------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| **`frequency`** | <code><a href="#reminderrecurrencefrequency">ReminderRecurrenceFrequency</a></code> | How frequent should the reminder repeat.                                                                |
| **`interval`**  | <code>number</code>                                                                 | The interval should be a number greater than 0. For values lower than 1 the method will throw an error. |
| **`end`**       | <code>number</code>                                                                 | When provided, the reminder will stop repeating at the given time.                                      |


#### RemindersList


### Type Aliases


#### PermissionState

<code>'prompt' | 'prompt-with-rationale' | 'granted' | 'denied'</code>


#### Access

<code>'granted' | 'denied'</code>


### Enums


#### PluginPermission

| Members               | Value                         | Description                                            |
| --------------------- | ----------------------------- | ------------------------------------------------------ |
| **`READ_CALENDAR`**   | <code>'readCalendar'</code>   | Represents the permission state for reading calendar.  |
| **`WRITE_CALENDAR`**  | <code>'writeCalendar'</code>  | Represents the permission state for writing calendar.  |
| **`READ_REMINDERS`**  | <code>'readReminders'</code>  | Represents the permission state for reading reminders. |
| **`WRITE_REMINDERS`** | <code>'writeReminders'</code> | Represents the permission state for writing reminders. |


#### CalendarChooserDisplayStyle

| Members                       | Description                                              |
| ----------------------------- | -------------------------------------------------------- |
| **`ALL_CALENDARS`**           | Display all calendars available for selection.           |
| **`WRITABLE_CALENDARS_ONLY`** | Display only writable calendars available for selection. |


#### CalendarChooserSelectionStyle

| Members        | Description                                             |
| -------------- | ------------------------------------------------------- |
| **`SINGLE`**   | Allows only a single selection in the calendar chooser. |
| **`MULTIPLE`** | Allows multiple selections in the calendar chooser.     |


#### ReminderRecurrenceFrequency

| Members       | Description                             |
| ------------- | --------------------------------------- |
| **`DAILY`**   | The reminder repeats on a daily basis   |
| **`WEEKLY`**  | The reminder repeats on a weekly basis  |
| **`MONTHLY`** | The reminder repeats on a monthly basis |
| **`YEARLY`**  | The reminder repeats on a yearly basis  |

</docgen-api>
