/**
 * Represents an event in the calendar.
 *
 * @interface CalendarEvent
 * @property id The unique identifier of the event.
 * @property title The title or name of the event.
 * @property location The location of the event.
 * @property eventColor The color of the individual event.
 * @property organizer The organizer of the event.
 * @property description The description of the event.
 * @property startDate The start date of the event.
 * @property endDate The end date of the event.
 * @property eventTimezone The timezone of the start date.
 * @property eventEndTimezone The timezone of the end date.
 * @property duration The duration of the event.
 * @property isAllDay Indicates if the event is all day.
 * @property calendarId The calendar that the event belongs to.
 */
export interface CalendarEvent {
  /**
   * @platform iOS, Android
   */
  id: string;

  /**
   * @platform iOS, Android
   */
  title?: string;

  /**
   * @platform iOS, Android
   */
  location?: string;

  /**
   * @platform Android
   */
  eventColor?: string;

  /**
   * @platform iOS, Android
   */
  organizer?: string;

  /**
   * @platform iOS, Android
   */
  description?: string;

  /**
   * @platform iOS, Android
   */
  startDate?: number;

  /**
   * @platform iOS, Android
   */
  endDate?: number;

  /**
   * @platform iOS, Android
   */
  eventTimezone?: string;

  /**
   * @platform iOS, Android
   */
  eventEndTimezone?: string;

  /**
   * @platform Android
   */
  duration?: string;

  /**
   * @platform iOS, Android
   */
  isAllDay?: boolean;

  /**
   * @platform iOS, Android
   */
  calendarId: string;
}
