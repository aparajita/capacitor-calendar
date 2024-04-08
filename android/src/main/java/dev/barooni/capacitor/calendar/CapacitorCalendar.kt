package dev.barooni.capacitor.calendar

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.CalendarContract
import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import java.util.Calendar
import java.util.TimeZone

class CapacitorCalendar() {
    var eventsCount: Int = 0

    @Throws(Exception::class)
    fun getTotalEventsCount(context: Context): Int {
        val contentResolver: ContentResolver = context.contentResolver
        val uri = CalendarContract.Events.CONTENT_URI
        val projection = arrayOf(CalendarContract.Events._ID)
        val cursor = contentResolver.query(uri, projection, null, null, null)
        val count = cursor?.count ?: 0
        cursor?.close()
        return count
    }

    @Throws(Exception::class)
    fun listCalendars(context: Context): JSArray {
        val projection =
            arrayOf(
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            )

        val calendars = JSArray()

        context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            null,
        )?.use { cursor ->
            val idColumnIndex = cursor.getColumnIndex(CalendarContract.Calendars._ID)
            val nameColumnIndex = cursor.getColumnIndex(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumnIndex)
                val title = cursor.getString(nameColumnIndex)
                val calendar =
                    JSObject().apply {
                        put("id", id)
                        put("title", title)
                    }

                calendars.put(calendar)
            }
        } ?: throw Exception("Cursor is null")

        return calendars
    }

    @Throws(Exception::class)
    fun getDefaultCalendar(context: Context): JSObject {
        val projection =
            arrayOf(
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
            )

        val selection = "${CalendarContract.Calendars.IS_PRIMARY} = ?"
        val selectionArgs = arrayOf("1")

        context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idColumnIndex = cursor.getColumnIndex(CalendarContract.Calendars._ID)
                val nameColumnIndex = cursor.getColumnIndex(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)
                val id = cursor.getLong(idColumnIndex)
                val title = cursor.getString(nameColumnIndex)

                val calendarObject =
                    JSObject().apply {
                        put("id", id.toString())
                        put("title", title)
                    }
                return calendarObject
            } else {
                throw Exception("No primary calendar found")
            }
        }
        throw Exception("No primary calendar found")
    }

    @Throws(Exception::class)
    fun createEvent(
        context: Context,
        title: String,
        calendarId: String?,
        location: String?,
        startDate: Long?,
        endDate: Long?,
        isAllDay: Boolean?,
        alertOffset: Int?,
    ): Uri? {
        val startMillis = startDate ?: Calendar.getInstance().timeInMillis
        val endMillis = endDate ?: (startMillis + 3600 * 1000)

        val values =
            ContentValues().apply {
                put(CalendarContract.Events.DTSTART, startMillis)
                put(CalendarContract.Events.DTEND, endMillis)
                put(CalendarContract.Events.TITLE, title)
                location?.let { put(CalendarContract.Events.EVENT_LOCATION, it) }
                put(CalendarContract.Events.CALENDAR_ID, calendarId ?: getDefaultCalendar(context).getString("id"))
                put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
                isAllDay?.let { put(CalendarContract.Events.ALL_DAY, if (it) 1 else 0) }
            }

        val uri = context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, values)

        if (alertOffset == null) {
            return uri
        }

        // Get the event ID
        val eventId = uri?.lastPathSegment?.toLong() ?: return uri

        // Add alert for the event
        val alertValues = ContentValues().apply {
            put(CalendarContract.Reminders.EVENT_ID, eventId)
            put(CalendarContract.Reminders.MINUTES, -alertOffset)
            put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
        }

        return context.contentResolver.insert(CalendarContract.Reminders.CONTENT_URI, alertValues)
    }

    @Throws(Exception::class)
    fun openCalendar(timestamp: Long): Intent {
        return Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("content://com.android.calendar/time/$timestamp")
        }
    }

    @Throws(Exception::class)
    fun listEventsInRange(
        context: Context,
        startDate: Long,
        endDate: Long,
    ): JSArray {
        val projection =
            arrayOf(
                CalendarContract.Events._ID,
                CalendarContract.Events.TITLE,
                CalendarContract.Events.EVENT_LOCATION,
                CalendarContract.Events.EVENT_COLOR,
                CalendarContract.Events.ORGANIZER,
                CalendarContract.Events.DESCRIPTION,
                CalendarContract.Events.DTSTART,
                CalendarContract.Events.DTEND,
                CalendarContract.Events.EVENT_TIMEZONE,
                CalendarContract.Events.EVENT_END_TIMEZONE,
                CalendarContract.Events.DURATION,
                CalendarContract.Events.ALL_DAY,
                CalendarContract.Events.CALENDAR_ID,
            )
        val selection = "(${CalendarContract.Events.DTSTART} >= ?) AND (${CalendarContract.Events.DTEND} <= ?)"
        val selectionArgs = arrayOf(startDate.toString(), endDate.toString())

        val events = JSArray()

        context.contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            null,
        )?.use { cursor ->
            val idColumnIndex = cursor.getColumnIndex(CalendarContract.Events._ID)
            val nameColumnIndex = cursor.getColumnIndex(CalendarContract.Events.TITLE)
            val locationColumnIndex = cursor.getColumnIndex(CalendarContract.Events.EVENT_LOCATION)
            val eventColorColumnIndex = cursor.getColumnIndex(CalendarContract.Events.EVENT_COLOR)
            val organizerColumnIndex = cursor.getColumnIndex(CalendarContract.Events.ORGANIZER)
            val descriptionColumnIndex = cursor.getColumnIndex(CalendarContract.Events.DESCRIPTION)
            val dtStartColumnIndex = cursor.getColumnIndex(CalendarContract.Events.DTSTART)
            val dtEndColumnIndex = cursor.getColumnIndex(CalendarContract.Events.DTEND)
            val eventTimezoneColumnIndex = cursor.getColumnIndex(CalendarContract.Events.EVENT_TIMEZONE)
            val eventEndTimezoneColumnIndex = cursor.getColumnIndex(CalendarContract.Events.EVENT_END_TIMEZONE)
            val durationColumnIndex = cursor.getColumnIndex(CalendarContract.Events.DURATION)
            val isAllDayColumnIndex = cursor.getColumnIndex(CalendarContract.Events.ALL_DAY)
            val calendarIdColumnIndex = cursor.getColumnIndex(CalendarContract.Events.CALENDAR_ID)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idColumnIndex)
                val title = cursor.getString(nameColumnIndex)
                val location = cursor.getString(locationColumnIndex)
                val eventColor = cursor.getInt(eventColorColumnIndex)
                val organizer = cursor.getString(organizerColumnIndex)
                val desc = cursor.getString(descriptionColumnIndex)
                val dtStart = cursor.getLong(dtStartColumnIndex)
                val dtEnd = cursor.getLong(dtEndColumnIndex)
                val eventTimezone = cursor.getString(eventTimezoneColumnIndex)
                val eventEndTimezone = cursor.getString(eventEndTimezoneColumnIndex)
                val duration = cursor.getString(durationColumnIndex)
                val allDay = cursor.getInt(isAllDayColumnIndex) == 1
                val calendarId = cursor.getLong(calendarIdColumnIndex)

                val event =
                    JSObject().apply {
                        put("id", id.toString())
                        title?.takeIf { it.isNotEmpty() }?.let { put("title", it) }
                        location?.takeIf { it.isNotEmpty() }?.let { put("location", it) }
                        eventColor.takeIf { it != 0 }?.let { put("eventColor", String.format("#%06X", 0xFFFFFF and it)) }
                        organizer?.takeIf { it.isNotEmpty() }?.let { put("organizer", it) }
                        desc?.takeIf { it.isNotEmpty() }?.let { put("description", it) }
                        dtStart.takeIf { it != 0.toLong() }?.let { put("startDate", it) }
                        dtEnd.takeIf { it != 0.toLong() }?.let { put("endDate", it) }
                        eventTimezone?.takeIf { it.isNotEmpty() }?.let { put("eventTimezone", it) }
                        eventEndTimezone?.takeIf { it.isNotEmpty() }?.let { put("eventEndTimezone", it) }
                        duration?.takeIf { it.isNotEmpty() }?.let { put("duration", it) }
                        put("isAllDay", allDay)
                        calendarId.takeIf { it != 0.toLong() }?.let { put("calendarId", it.toString()) }
                    }
                events.put(event)
            }
        } ?: throw Exception("Cursor is null")
        return events
    }
}
