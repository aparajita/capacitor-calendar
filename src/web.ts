/* eslint-disable @typescript-eslint/no-unused-vars */
import { PermissionState, WebPlugin } from '@capacitor/core';
import { CapacitorCalendarPlugin } from './definitions';
import { PluginPermission } from './schemas/enums/plugin-permission';
import { ReminderRecurrenceRule } from './schemas/interfaces/reminder-recurrence-rule';
import type { Calendar } from './schemas/interfaces/calendar';
import type { RemindersList } from './schemas/interfaces/reminders-list';
import type { PluginPermissionsMap } from './schemas/interfaces/plugin-permissions-map';
import type { CalendarEvent } from './schemas/interfaces/calendar-event';

export class CapacitorCalendarWeb extends WebPlugin implements CapacitorCalendarPlugin {
  public checkPermission(_options: { alias: PluginPermission }): Promise<{ result: PermissionState }> {
    throw this.unimplemented(`${this.checkPermission.name} is not implemented on the web`);
  }

  public checkAllPermissions(): Promise<PluginPermissionsMap> {
    throw this.unimplemented(`${this.checkAllPermissions.name} is not implemented on the web`);
  }

  public requestPermission(_options: { alias: PluginPermission }): Promise<{ result: PermissionState }> {
    throw this.unimplemented(`${this.requestPermission.name} is not implemented on the web`);
  }

  public requestAllPermissions(): Promise<PluginPermissionsMap> {
    throw this.unimplemented(`${this.requestAllPermissions.name} is not implemented on the web`);
  }

  public createEventWithPrompt(): Promise<{ result: string[] }> {
    throw this.unimplemented(`${this.createEventWithPrompt.name} is not implemented on the web`);
  }

  public selectCalendarsWithPrompt(): Promise<{ result: Calendar[] }> {
    throw this.unimplemented(`${this.createEventWithPrompt.name} is not implemented on the web`);
  }

  public listCalendars(): Promise<{ result: Calendar[] }> {
    throw this.unimplemented(`${this.listCalendars.name} is not implemented on the web`);
  }

  public getDefaultCalendar(): Promise<{ result: Calendar }> {
    throw this.unimplemented(`${this.getDefaultCalendar.name} is not implemented on the web`);
  }

  public createEvent(_options: {
    title: string;
    calendarId?: string;
    location?: string;
    startDate?: number;
    endDate?: number;
    isAllDay?: boolean;
  }): Promise<{
    result: string;
  }> {
    throw this.unimplemented(`${this.createEvent.name} is not implemented on the web`);
  }

  public createReminder(_options: {
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
  }): Promise<{ result: string }> {
    throw this.unimplemented(`${this.createReminder.name} is not implemented on the web`);
  }

  public getDefaultRemindersList(): Promise<{ result: RemindersList }> {
    throw this.unimplemented(`${this.createReminder.name} is not implemented on the web`);
  }

  public getRemindersLists(): Promise<{ result: RemindersList[] }> {
    throw this.unimplemented(`${this.createReminder.name} is not implemented on the web`);
  }

  public openCalendar(_options: { date?: number }): Promise<void> {
    throw this.unimplemented(`${this.createReminder.name} is not implemented on the web`);
  }

  public openReminders(): Promise<void> {
    throw this.unimplemented(`${this.createReminder.name} is not implemented on the web`);
  }

  public listEventsInRange(_options: { startDate: number; endDate: number }): Promise<{ result: CalendarEvent[] }> {
    throw this.unimplemented(`${this.createReminder.name} is not implemented on the web`);
  }

  public deleteEventsById(_options: { ids: string[] }): Promise<{
    result: { deleted: string[]; failed: string[] };
  }> {
    throw this.unimplemented(`${this.deleteEventsById.name} is not implemented on the web`);
  }
}
