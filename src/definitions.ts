import { CalendarChooserDisplayStyle } from './schemas/enums/calendar-chooser-display-style';
import { CalendarChooserSelectionStyle } from './schemas/enums/calendar-chooser-selection-style';
import { PluginPermission } from './schemas/enums/plugin-permission';
import type { PermissionState } from '@capacitor/core';
import type { Access } from './schemas/interfaces/access';
import type { Calendar } from './schemas/interfaces/calendar';
import type { RemindersList } from './schemas/interfaces/reminders-list';
import type { PluginPermissionsMap } from './schemas/interfaces/plugin-permissions-map';
import type { ReminderRecurrenceRule } from './schemas/interfaces/reminder-recurrence-rule';
import type { CalendarEvent } from './schemas/interfaces/calendar-event';

export interface CapacitorCalendarPlugin {
  /**
   * Checks the current authorization status of a specific permission.
   *
   * @platform iOS, Android
   * @throws CapacitorException with .data.type:
   * - ErrorType.missingKey if alias is not provided.
   * - ErrorType.invalidKey if alias is not a PluginPermission.
   * @example
   * const status = await CapacitorCalendar.checkPermission({ alias: 'readCalendar' });
   */
  checkPermission(options: { alias: PluginPermission }): Promise<{ result: PermissionState }>;

  /**
   * Checks the current authorization status of all the required permissions for the plugin.
   *
   * @platform iOS, Android
   * @since 6.4.0
   */
  checkAllPermissions(): Promise<PluginPermissionsMap>;

  /**
   * [Android only] Requests read-only access to the calendar. If access has
   * not already been granted or denied, the user will be prompted to grant it.
   *
   * @platform Android
   * @since 6.4.0
   */
  requestReadOnlyCalendarAccess(): Promise<{ result: Access }>;

  /**
   * Requests write-only access to the calendar. If access has not already
   * been granted or denied, the user will be prompted to grant it.
   *
   * Note: On iOS < 17, requesting write-only access is the same as read/write.
   *
   * @platform iOS, Android
   * @since 6.4.0
   */
  requestWriteOnlyCalendarAccess(): Promise<{ result: Access }>;

  /**
   * Requests read/write access to the calendar. If access has not already
   * been granted or denied, the user will be prompted to grant it.
   *
   * @platform iOS, Android
   * @since 6.4.0
   */
  requestFullCalendarAccess(): Promise<{ result: Access }>;

  /**
   * [iOS only] Requests read/write access to reminders. If access has not already
   * been granted or denied, the user will be prompted to grant it.
   *
   * @platform iOS
   * @since 6.4.0
   */
  requestFullRemindersAccess(): Promise<{ result: Access }>;

  /**
   * Requests authorization to all required permissions for the plugin.
   * If any of the permissions have not yet been granted or denied,
   * the user will be prompted to grant them.
   *
   * @platform iOS, Android
   */
  requestAllPermissions(): Promise<PluginPermissionsMap>;

  /**
   * Requests authorization to a specific permission, if not already granted.
   * If the permission is already granted, it will directly return the status.
   *
   * @deprecated Use the specific request*Access methods instead
   * @platform iOS, Android
   * @example
   * const result = await CapacitorCalendar.requestPermission({ alias: 'readCalendar' });
   */
  requestPermission(options: { alias: PluginPermission }): Promise<{ result: PermissionState }>;

  /**
   * Retrieves a list of calendars available on the device.
   *
   * @platform iOS, Android
   * @param options Options for customizing the display and selection styles of the calendar chooser.
   * @param options.access Whether to return all or only writeable calendars. Defaults to CalendarChooserDisplayStyle.ALL_CALENDARS.
   * @returns A promise that resolves to an array of calendars available on the device.
   * @throws CapacitorException with .data.type === ErrorType.noAccess
   * if calendar read access hos not been granted.
   * @example
   * const { result } = await CapacitorCalendar.listCalendars({ access: CalendarChooserDisplayStyle.WRITABLE_CALENDARS_ONLY });
   * console.log(result); // [{ id: '1', title: 'Work Calendar' }, { id: '2', title: 'Personal Calendar' }]
   */
  listCalendars(options?: { access: CalendarChooserDisplayStyle }): Promise<{ result: Calendar[] }>;

  /**
   * Retrieves the default calendar on the device.
   *
   * @platform iOS, Android
   * @returns A promise that resolves to the default calendar on the device,
   * or null if no default calendar is available, usually because the device
   * calendar has not been set up.
   * @throws CapacitorException with .data.type === ErrorType.noAccess
   * if calendar read access hos not been granted.
   * @example
   * const { result } = await CapacitorCalendar.getDefaultCalendar();
   * console.log(result); // { id: '1', title: 'Default Calendar', writeable: true }
   */
  getDefaultCalendar(): Promise<{ result: Calendar | null }>;

  /**
   * [iOS only] Presents a prompt to the user to select calendars.
   *
   * @since 0.2.0
   * @platform iOS
   * @permissions
   * <h3>Runtime Permissions:</h3>
   * <ul>
   *   <li><strong>iOS:</strong> writeCalendar</li>
   * </ul>
   * @param options Options for customizing the display and selection styles of the calendar chooser.
   * @param options.displayStyle To show all or only writeable calendars.
   * @param options.selectionStyle To be able to select multiple calendars or only one.
   * @returns A promise that resolves to an array of selected calendars.
   * If calendar read access has not been granted, the calendar chooser will
   * alert the user to that fact and the returned array will be empty.
   * @throws CapacitorException with .data.type:
   * - ErrorType.noAccess if the user has not granted read access.
   * - ErrorType.missingKey if either of the options properties are missing.
   * - ErrorType.osError if the OS generates an error.
   * @example
   * if (Capacitor.getPlatform() === 'ios') {
   *     const { result } = await CapacitorCalendar.selectCalendarsWithPrompt();
   *     console.log(result); // [{ id: '1', title: 'Work Calendar', writeable: true }]
   * }
   */
  selectCalendarsWithPrompt(options: {
    displayStyle: CalendarChooserDisplayStyle;
    selectionStyle: CalendarChooserSelectionStyle;
  }): Promise<{ result: Calendar[] }>;

  /**
   * [iOS only] Creates a calendar.
   *
   * @since 5.2.0
   * @platform iOS
   * @permissions
   * <h3>Runtime Permissions:</h3>
   * <ul>
   *   <li><strong>iOS:</strong> readCalendar, writeCalendar</li>
   * </ul>
   * @param options Options for creating a calendar.
   * @param options.title The title of the calendar to create.
   * @param [options.color] The color of the calendar to create.
   * The color should be a hex RRGGBB string (case-insensitive),
   * with or without a leading '#'.
   * @returns A Promise that resolves to the id of the created calendar.
   * @throws CapacitorException with .data.type:
   * - ErrorType.noAccess if calendar write access hos not been granted.
   * - ErrorType.missingKey if the title is missing or empty.
   * @example
   * { result } = await CapacitorCalendar.createCalendar({
   *      title: 'New Calendar',
   *      color: '#1d00fc',
   *  });
   *  console.log(result);   // 'CALENDAR_ID'
   */
  createCalendar(options: { title: string; color?: string }): Promise<{ result: string }>;

  /**
   * [iOS only] Deletes a calendar by id.
   *
   * @since 5.2.0
   * @platform iOS
   * @permissions
   * <h3>Runtime Permissions:</h3>
   * <ul>
   *   <li><strong>iOS:</strong> readCalendar, writeCalendar</li>
   * </ul>
   * @param options Options for deleting a calendar.
   * @param options.id The id of the calendar to delete.
   * @throws CapacitorException with .data.type:
   * - ErrorType.noAccess if calendar write access hos not been granted.
   * - ErrorType.missingKey if the id is missing or empty.
   * @example
   * await CapacitorCalendar.deleteCalendar({ id: 'ID_1' });
   */
  deleteCalendar(options: { id: string }): Promise<void>;

  /**
   * Opens the native calendar app, which will suspend your app.
   * The calendar will open to today's date if no date is provided.
   *
   * @method openCalendar
   * @platform iOS, Android
   * @param options Options for opening the calendar.
   * @param options.date The date at which the calendar should be opened,
   * represented in milliseconds since January 1, 1970 UTC.
   * @throws CapacitorException with .data.type === .osError if the OS generates an error.
   * @example
   * void CapacitorCalendar.openCalendar({ date: person.birthDate.getTime() });
   */
  openCalendar(options: { date?: number }): Promise<void>;

  /**
   * Creates an event with the provided options.
   *
   * @platform iOS, Android
   * @permissions
   * <h3>Runtime Permissions:</h3>
   * <ul>
   *   <li><strong>iOS:</strong> writeCalendar</li>
   *   <li><strong>Android:</strong> readCalendar, writeCalendar</li>
   * </ul>
   * @param options Options for creating the event.
   * @param options.title The title of the event.
   * @param [options.calendarId] The id of the destination calendar, or the default calendar if not provided.
   * @param [options.location] The location of the event.
   * @param [options.startDate] The start date and time of the event.
   * @param [options.endDate] The end date and time of the event.
   * @param [options.isAllDay] Whether the event is for the entire day or not.
   * @param [options.alertOffsetInMinutes] If a number >= 0 is provided, an alert will be set for the event this many
   * minutes *before* the event. Negative values are ignored.
   * @throws CapacitorException with .data.type:
   * - ErrorType.noAccess if calendar write access hos not been granted.
   * - ErrorType.noDefaultCalendar if options.calendarId is not provided or invalid
   * and there is no default calendar available.
   * - ErrorType.osError if the OS generates an error.
   * @example
   * const now = Date.now();
   * const eventOptions = {
   *   title: 'Team Meeting',
   *   location: 'Conference Room A',
   *   startDate: now,
   *   endDate: now + 2 * 60 * 60 * 1000,
   *   isAllDay: false,
   *   alertOffsetInMinutes: 5,
   * };
   * const { result } = await CapacitorCalendar.createEvent(eventOptions);
   */
  createEvent(options: {
    title: string;
    calendarId?: string;
    location?: string;
    startDate?: number;
    endDate?: number;
    isAllDay?: boolean;
    alertOffsetInMinutes?: number;
  }): Promise<{ result: string }>;

  /**
   * Creates an event in the calendar by using the native calendar.
   * On iOS opens a native sheet and on Android opens an intent.
   *
   * @since 0.1.0
   * @platform iOS, Android
   * @permissions
   * <h3>Runtime Permissions:</h3>
   * <ul>
   *   <li><strong>Android:</strong> readCalendar</li>
   * </ul>
   * @param options Options for creating the event.
   * @param options.title The title of the event.
   * @param [options.calendarId] The id of the destination calendar or the default calendar if not provided.
   * @param [options.location] The location of the event.
   * @param [options.startDate] The start date and time of the event.
   * @param [options.endDate] The end date and time of the event.
   * @param [options.isAllDay] Whether the event is for the entire day or not.
   * @param [options.alertOffsetInMinutes] Ignored on Android. If a number >= 0 is provided,
   * an alert will be set for the event this many minutes *before* the event.
   * Negative values are ignored.
   * @throws CapacitorException with .data.type:
   * - ErrorType.noAccess if calendar write access hos not been granted.
   * - ErrorType.noDefaultCalendar if options.calendarId is not provided or invalid
   * and there is no default calendar available.
   * - ErrorType.osError if the OS generates an error.
   * @returns A promise that resolves to an array of event ids.
   * @example
   * if (capacitor.getPlatform() === 'android') {
   *     await this.requestPermission({ alias: 'readCalendar' });
   *     { result } = result = await this.createEventWithPrompt({
   *        title: 'Title',
   *        alertOffsetInMinutes: 5,
   *     });
   * } else {
   *     { result } = result = await this.createEventWithPrompt({
   *        title: 'Title',
   *        alertOffsetInMinutes: 5,
   *     });
   * }
   */
  createEventWithPrompt(options: {
    title: string;
    calendarId?: string;
    location?: string;
    startDate?: number;
    endDate?: number;
    isAllDay?: boolean;
    alertOffsetInMinutes?: number;
  }): Promise<{ result: string[] }>;

  /**
   * Retrieves a list of calendar events present in the given date range.
   *
   * @since 0.10.0
   * @platform iOS, Android
   * @permissions
   * <h3>Runtime Permissions:</h3>
   * <ul>
   *   <li><strong>iOS:</strong> readCalendar</li>
   *   <li><strong>Android:</strong> readCalendar</li>
   * </ul>
   * @param options Options for defining the date range.
   * @param options.startDate The start of the date range in milliseconds since January 1, 1970 UTC.
   * @param options.endDate The end of the date range in milliseconds since January 1, 1970 UTC.
   * @returns A Promise that resolves to the list of events.
   * @throws CapacitorException with .data.type === ErrorType.noAccess
   * if calendar read access hos not been granted.
   * @example
   * const { result } = await CapacitorCalendar.listEventsInRange({
   *   startDate: Date.now(),
   *   endDate: Date.now() + 6 * 7 * 24 * 60 * 60 * 1000, // 6 weeks from now
   * })
   */
  listEventsInRange(options: { startDate: number; endDate: number }): Promise<{ result: CalendarEvent[] }>;

  /**
   * Deletes events from the calendar given their IDs.
   *
   * @since 0.11.0
   * @platform iOS, Android
   * @permissions
   * <h3>Runtime Permissions:</h3>
   * <ul>
   *   <li><strong>iOS:</strong> writeCalendar</li>
   *   <li><strong>Android:</strong> writeCalendar</li>
   * </ul>
   * @param options Options for defining event IDs.
   * @param options.ids An array of event IDs to be deleted.
   * @throws CapacitorException with .data.type:
   * - ErrorType.noAccess if calendar write access hos not been granted.
   * - ErrorType.osError if the OS generates an error.
   * @returns A promise that resolves to an object with two properties:
   *  - deleted: string[] - An array of IDs that were successfully deleted.
   *  - failed: string[] - An array of IDs that could not be deleted.
   * @example
   * const idsToDelete = ['ID_1', 'ID_2', 'ID_DOES_NOT_EXIST'];
   * const { result } = await CapacitorCalendar.deleteEventsById(idsToDelete)
   * console.log(result.deleted)  // ['ID_1', 'ID_2']
   * console.log(result.failed) // ['ID_DOES_NOT_EXIST']
   */
  deleteEventsById(options: { ids: string[] }): Promise<{ result: { deleted: string[]; failed: string[] } }>;

  /**
   * [iOS only] Creates a reminder with the provided options.
   *
   * @since 0.5.0
   * @platform iOS
   * @permissions
   * <h3>Runtime Permissions:</h3>
   * <ul>
   *   <li><strong>iOS:</strong> writeReminders</li>
   * </ul>
   * @param options Options for creating the reminder.
   * @param options.title The title of the reminder.
   * @param options.listId The id of the destination reminders list.
   * @param [options.priority] The priority of the reminder. A number between one and nine where nine
   * has theiority and 0 means no priority at all. Values outside of this range will be rounded to the
   * nearest(Optional)
   * @param [options.isCompleted] Whether the reminder is completed already or not.
   * @param [options.startDate] The start date of the reminder.
   * @param [options.dueDate] The due date of the reminder.
   * @param [options.completionDate] The date at which the reminder was completed.
   * @param [options.notes] Additional notes about the reminder.
   * @param [options.url] A URL to save under the reminder.
   * @param [options.location] A location to save under the reminder.
   * @param [options.recurrence] The rules for the recurrence of the reminder.
   * @returns A Promise that resolves to the id of the created reminder.
   * @throws CapacitorException with .data.type:
   * - ErrorType.noAccess if reminders write access hos not been granted.
   * - ErrorType.osError if the OS generates an error.
   * @example
   * const now = Date.now();
   * const rules: ReminderRecurrenceRule = {
   *     frequency: ReminderRecurrenceFrequency.MONTHLY,
   *     interval: 10,
   *     end: Date.now()
   * }
   * const reminderOptions = {
   *   title: 'Buy cucumber',
   *   listId: 'ABC12',
   *   priority: 5,
   *   isCompleted: false,
   *   startDateComponents: now,
   *   notes: 'Also buy tomatoes',
   *   url: 'https://capacitor-calendar.pages.dev/',
   *   location: 'My Local Supermarket',
   *   recurrence: rules
   * };
   * const { result } = await CapacitorCalendar.createReminder(reminderOptions);
   * console.log(result); // 'ID_1'
   */
  createReminder(options: {
    title: string;
    listId?: string;
    priority?: number;
    isCompleted?: boolean;
    startDate?: number;
    dueDate?: number;
    completionDate?: number;
    notes?: string;
    url?: string;
    location?: string;
    recurrence?: ReminderRecurrenceRule;
  }): Promise<{ result: string }>;

  /**
   * [iOS only] Retrieves the default reminders list on the device.
   *
   * @method getDefaultRemindersList
   * @platform iOS
   * @returns A promise that resolves to the default reminder list on the device.
   * @throws CapacitorException with .data.type:
   * - ErrorType.noAccess if reminders read access hos not been granted.
   * - ErrorType.osError if the OS generates an error.
   * @example
   * const { result } = await CapacitorCalendar.getDefaultRemindersList();
   * console.log(result); // { id: '1', title: 'Default Reminders List', writeable: true }
   */
  getDefaultRemindersList(): Promise<{ result: RemindersList }>;

  /**
   * [iOS only] Retrieves all available reminders lists on the device.
   *
   * @platform iOS
   * @returns A promise that resolves with an array of reminders lists available on the device.
   * @throws CapacitorException with .data.type:
   * - ErrorType.noAccess if reminders read access hos not been granted.
   * - ErrorType.osError if the OS generates an error.
   * @example
   * const { result } = await CapacitorCalendar.getRemindersLists();
   * console.log(result); // [{ id: '1', title: 'Groceries', writeable: true }, { id: '2', title: 'Subscriptions', writeable: true }]
   */
  getRemindersLists(): Promise<{ result: RemindersList[] }>;

  /**
   * [iOS only] Opens the native calendar app, which will suspend your app.
   * The calendar will open to today's date if no date is provided.
   *
   * @platform iOS
   * @throws CapacitorException with .data.type === ErrorType.osError if the OS generates an error.
   */
  openReminders(): Promise<void>;
}
