/**
 * Represents a calendar object.
 *
 * @interface Calendar
 * @platform iOS, Android
 * @property {string} id - The unique identifier of the calendar.
 * @property {string} title - The title or name of the calendar.
 * @property {boolean} writable - Indicates if the calendar is writeable.
 */
export interface Calendar {
  id: string;
  title: string;
  writable: boolean;
}
