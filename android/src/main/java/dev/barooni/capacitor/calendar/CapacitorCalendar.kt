package dev.barooni.capacitor.calendar

import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.CalendarContract
import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import java.util.Calendar
import java.util.TimeZone

class CapacitorCalendar {
    enum class AccessMode {
        ALL,
        WRITEABLE_ONLY,
        ;

        companion object {
            fun fromInt(value: Int): AccessMode {
                return when (value) {
                    0 -> ALL
                    1 -> WRITEABLE_ONLY
                    else -> throw IllegalArgumentException("Invalid integer value for AccessMode")
                }
            }
        }
    }

    private data class JSCalendar(
        val id: Long,
        val title: String,
        val writeable: Boolean,
    ) {
        fun toJSObject(): JSObject {
            return JSObject().apply {
                put("id", id.toString())
                put("title", title)
                put("writeable", writeable)
            }
        }
    }

    private var eventIdsArray: List<Long> = emptyList()

    // Calendars

    @Throws(Exception::class)
    fun fetchCalendarEventIDs(context: Context): List<Long> {
        val projection = arrayOf(CalendarContract.Events._ID)
        val uri = CalendarContract.Events.CONTENT_URI
        val cursor = context.contentResolver.query(uri, projection, null, null, null)
        val eventIds = mutableListOf<Long>()

        cursor?.use {
            while (it.moveToNext()) {
                val eventId = it.getLong(0)
                eventIds.add(eventId)
            }
        }

        eventIdsArray = eventIds
        return eventIds
    }

    @Throws(Exception::class)
    fun getNewEventIds(newIds: List<Long>): List<Long> {
        return newIds.filterNot { it in eventIdsArray }
    }

    private fun calendarIsWriteable(cursor: android.database.Cursor): Boolean {
        val accessLevelIndex =
            cursor.getColumnIndex(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL)
        val accessLevel = cursor.getInt(accessLevelIndex)

        return accessLevel == CalendarContract.Calendars.CAL_ACCESS_OWNER ||
            accessLevel == CalendarContract.Calendars.CAL_ACCESS_CONTRIBUTOR
    }

    private fun calendarFromCursor(cursor: android.database.Cursor): JSCalendar {
        val idIndex = cursor.getColumnIndex(CalendarContract.Calendars._ID)
        val id = cursor.getLong(idIndex)

        val nameIndex =
            cursor.getColumnIndex(CalendarContract.Calendars.CALENDAR_DISPLAY_NAME)
        val title = cursor.getString(nameIndex)
        val writeable = calendarIsWriteable(cursor)

        return JSCalendar(id, title, writeable)
    }

    @Throws(Exception::class)
    fun listCalendars(
        context: Context,
        access: AccessMode,
    ): JSArray {
        val projection =
            arrayOf(
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
            )

        val calendars = JSArray()

        context.contentResolver.query(
            CalendarContract.Calendars.CONTENT_URI,
            projection,
            null,
            null,
            null,
        )?.use { cursor ->
            while (cursor.moveToNext()) {
                val calendar = calendarFromCursor(cursor)

                if (access == AccessMode.WRITEABLE_ONLY && !calendar.writeable) {
                    continue
                }

                calendars.put(calendar.toJSObject())
            }
        } ?: throw PluginException(
            PluginException.ErrorType.INTERNAL_ERROR,
            CapacitorCalendar::listCalendars.name,
            "Cursor is null",
        )

        return calendars
    }

    @Throws(Exception::class)
    fun getDefaultCalendar(context: Context): JSObject? {
        val projection =
            arrayOf(
                CalendarContract.Calendars._ID,
                CalendarContract.Calendars.CALENDAR_DISPLAY_NAME,
                CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL,
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
                return calendarFromCursor(cursor).toJSObject()
            } else {
                return null
            }
        } ?: throw PluginException(
            PluginException.ErrorType.INTERNAL_ERROR,
            CapacitorCalendar::getDefaultCalendar.name,
            "Cursor is null",
        )
    }

    @Throws(Exception::class)
    fun openCalendar(timestamp: Long): Intent {
        return Intent(Intent.ACTION_VIEW).apply {
            data = Uri.parse("content://com.android.calendar/time/$timestamp")
        }
    }

    // Events

    @Throws(Exception::class)
    fun createEvent(
        context: Context,
        title: String,
        calendarId: String?,
        location: String?,
        startDate: Long?,
        endDate: Long?,
        isAllDay: Boolean?,
        alertOffsetInMinutes: Float?,
    ): Uri? {
        val startMillis = startDate ?: Calendar.getInstance().timeInMillis
        val endMillis = endDate ?: (startMillis + 3600 * 1000)
        var id = calendarId

        if (id == null) {
            val defaultCalendar =
                getDefaultCalendar(context) ?: throw PluginException(
                    PluginException.ErrorType.NO_DEFAULT_CALENDAR,
                    CapacitorCalendar::createEvent.name,
                )
            id = defaultCalendar.getString("id")
        }

        val eventValues =
            ContentValues().apply {
                put(CalendarContract.Events.DTSTART, startMillis)
                put(CalendarContract.Events.DTEND, endMillis)
                put(CalendarContract.Events.TITLE, title)
                location?.let { put(CalendarContract.Events.EVENT_LOCATION, it) }
                put(CalendarContract.Events.CALENDAR_ID, id)
                put(CalendarContract.Events.EVENT_TIMEZONE, TimeZone.getDefault().id)
                isAllDay?.let { put(CalendarContract.Events.ALL_DAY, if (it) 1 else 0) }
            }

        val eventUri =
            context.contentResolver.insert(CalendarContract.Events.CONTENT_URI, eventValues)

        if (alertOffsetInMinutes == null || alertOffsetInMinutes < 0) {
            return eventUri
        }

        val eventId =
            eventUri?.lastPathSegment?.toLong()
                ?: throw PluginException(
                    PluginException.ErrorType.INTERNAL_ERROR,
                    "Failed to convert event id to long",
                )
        val alertValues =
            ContentValues().apply {
                put(CalendarContract.Reminders.EVENT_ID, eventId)
                put(CalendarContract.Reminders.MINUTES, alertOffsetInMinutes)
                put(CalendarContract.Reminders.METHOD, CalendarContract.Reminders.METHOD_ALERT)
            }

        context.contentResolver.insert(CalendarContract.Reminders.CONTENT_URI, alertValues)
        return eventUri
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
        val selection =
            "(${CalendarContract.Events.DTSTART} >= ?) AND (${CalendarContract.Events.DTEND} <= ?)"
        val selectionArgs = arrayOf(startDate.toString(), endDate.toString())
        val events = JSArray()

        context.contentResolver.query(
            CalendarContract.Events.CONTENT_URI,
            projection,
            selection,
            selectionArgs,
            null,
        )?.use { cursor ->
            val idIndex = cursor.getColumnIndex(CalendarContract.Events._ID)
            val nameIndex = cursor.getColumnIndex(CalendarContract.Events.TITLE)
            val locationIndex = cursor.getColumnIndex(CalendarContract.Events.EVENT_LOCATION)
            val eventColorIndex = cursor.getColumnIndex(CalendarContract.Events.EVENT_COLOR)
            val organizerIndex = cursor.getColumnIndex(CalendarContract.Events.ORGANIZER)
            val descriptionIndex = cursor.getColumnIndex(CalendarContract.Events.DESCRIPTION)
            val dtStartIndex = cursor.getColumnIndex(CalendarContract.Events.DTSTART)
            val dtEndIndex = cursor.getColumnIndex(CalendarContract.Events.DTEND)
            val eventTimezoneIndex =
                cursor.getColumnIndex(CalendarContract.Events.EVENT_TIMEZONE)
            val eventEndTimezoneIndex =
                cursor.getColumnIndex(CalendarContract.Events.EVENT_END_TIMEZONE)
            val durationIndex = cursor.getColumnIndex(CalendarContract.Events.DURATION)
            val isAllDayIndex = cursor.getColumnIndex(CalendarContract.Events.ALL_DAY)
            val calendarIdIndex = cursor.getColumnIndex(CalendarContract.Events.CALENDAR_ID)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex)
                val title = cursor.getString(nameIndex)
                val location = cursor.getString(locationIndex)
                val eventColor = cursor.getInt(eventColorIndex)
                val organizer = cursor.getString(organizerIndex)
                val desc = cursor.getString(descriptionIndex)
                val dtStart = cursor.getLong(dtStartIndex)
                val dtEnd = cursor.getLong(dtEndIndex)
                val eventTimezone = cursor.getString(eventTimezoneIndex)
                val eventEndTimezone = cursor.getString(eventEndTimezoneIndex)
                val duration = cursor.getString(durationIndex)
                val allDay = cursor.getInt(isAllDayIndex) == 1
                val calendarId = cursor.getLong(calendarIdIndex)

                val event =
                    JSObject().apply {
                        put("id", id.toString())
                        title?.takeIf { it.isNotEmpty() }?.let { put("title", it) }
                        location?.takeIf { it.isNotEmpty() }?.let { put("location", it) }
                        eventColor.takeIf { it != 0 }
                            ?.let { put("eventColor", String.format("#%06X", 0xFFFFFF and it)) }
                        organizer?.takeIf { it.isNotEmpty() }?.let { put("organizer", it) }
                        desc?.takeIf { it.isNotEmpty() }?.let { put("description", it) }
                        dtStart.takeIf { it != 0.toLong() }?.let { put("startDate", it) }
                        dtEnd.takeIf { it != 0.toLong() }?.let { put("endDate", it) }
                        eventTimezone?.takeIf { it.isNotEmpty() }?.let { put("eventTimezone", it) }
                        eventEndTimezone?.takeIf { it.isNotEmpty() }
                            ?.let { put("eventEndTimezone", it) }
                        duration?.takeIf { it.isNotEmpty() }?.let { put("duration", it) }
                        put("isAllDay", allDay)
                        calendarId.takeIf { it != 0.toLong() }
                            ?.let { put("calendarId", it.toString()) }
                    }
                events.put(event)
            }
        } ?: throw Exception("Cursor is null")

        return events
    }

    @Throws(Exception::class)
    fun deleteEventsById(
        context: Context,
        ids: JSArray,
    ): JSObject {
        val deleted = JSArray()
        val failed = JSArray()
        val contentResolver = context.contentResolver

        ids.toList<String>().forEach { id ->
            try {
                val uri =
                    ContentUris.withAppendedId(CalendarContract.Events.CONTENT_URI, id.toLong())

                // Before deleting, we have to determine if the event's calendar is writeable.
                val eventCursor =
                    context.contentResolver.query(
                        uri,
                        arrayOf(CalendarContract.Events.CALENDAR_ID),
                        null,
                        null,
                        null,
                    )
                val calendarId =
                    eventCursor?.use {
                        if (it.moveToFirst()) {
                            it.getLong(it.getColumnIndexOrThrow(CalendarContract.Events.CALENDAR_ID))
                        } else {
                            throw Exception("Event not found")
                        }
                    } ?: throw Exception("Calendar not found")

                val calendarUri =
                    ContentUris.withAppendedId(CalendarContract.Calendars.CONTENT_URI, calendarId)

                context.contentResolver.query(
                    calendarUri,
                    arrayOf(CalendarContract.Calendars.CALENDAR_ACCESS_LEVEL),
                    null,
                    null,
                    null,
                )?.use {
                    if (it.moveToFirst()) {
                        if (!calendarIsWriteable(it)) {
                            throw Exception("Calendar is not writeable")
                        }
                    } else {
                        throw Exception("Calendar not found")
                    }
                }

                // If we get to this point, we can safely delete the event.
                val rowsDeleted = contentResolver.delete(uri, null, null)

                if (rowsDeleted > 0) {
                    deleted.put(id)
                } else {
                    failed.put(id)
                }
            } catch (error: Exception) {
                failed.put(id)
            }
        }

        return JSObject().apply {
            put("deleted", deleted)
            put("failed", failed)
        }
    }
}
