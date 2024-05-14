import { registerPlugin } from '@capacitor/core';
import { CalendarChooserDisplayStyle } from './schemas/enums/calendar-chooser-display-style';
import { CalendarChooserSelectionStyle } from './schemas/enums/calendar-chooser-selection-style';
import { ErrorType } from './schemas/enums/error-type';
import { PluginPermission } from './schemas/enums/plugin-permission';
import { ReminderRecurrenceFrequency } from './schemas/enums/reminder-recurrence-frequency';
import type { CapacitorCalendarPlugin } from './definitions';
import type { Access } from './schemas/interfaces/access';
import type { Calendar } from './schemas/interfaces/calendar';
import type { RemindersList } from './schemas/interfaces/reminders-list';
import type { PluginPermissionsMap } from './schemas/interfaces/plugin-permissions-map';
import type { ReminderRecurrenceRule } from './schemas/interfaces/reminder-recurrence-rule';
import type { CalendarEvent } from './schemas/interfaces/calendar-event';

const CapacitorCalendar = registerPlugin<CapacitorCalendarPlugin>('CapacitorCalendar', {
  web: () => import('./web').then((m) => new m.CapacitorCalendarWeb()),
});

export * from './definitions';
export type { Access, Calendar, RemindersList, ReminderRecurrenceRule };
export {
  CalendarEvent,
  CapacitorCalendar,
  CalendarChooserSelectionStyle,
  CalendarChooserDisplayStyle,
  ErrorType,
  PluginPermission,
  PluginPermissionsMap,
  ReminderRecurrenceFrequency,
};
