/**
 * When an error occurs, the plugin will return an error type
 * in error.data.type (which is typed as any). This enum contains all possible
 * error types, so you can use this enum to check for specific errors:
 *
 * @since 6.4.0
 * @example
 * try {
 *   const response = await CapacitorCalendar.selectCalendarsWithPrompt();
 * } catch (error) {
 *   if (error instanceof CapacitorException && error.data?.['type'] === ErrorType.noAccess) {
 *     console.log('No access to calendar');
 *   }
 * }
 */
export enum ErrorType {
  missingKey = 'missingKey',
  invalidKey = 'invalidKey',
  noAccess = 'noAccess',
  calendarNotFound = 'calendarNotFound',
  noDefaultCalendar = 'noDefaultCalendar',
  unableToOpenCalendar = 'unableToOpenCalendar',
  unableToOpenReminders = 'unableToOpenReminders',
  noViewController = 'noViewController',
  osError = 'osError',
  internalError = 'internalError',
  unknownError = 'unknownError',
}
