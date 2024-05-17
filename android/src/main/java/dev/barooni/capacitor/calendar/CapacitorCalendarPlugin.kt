package dev.barooni.capacitor.calendar

import android.Manifest
import android.content.Intent
import android.provider.CalendarContract
import androidx.activity.result.ActivityResult
import com.getcapacitor.JSArray
import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.ActivityCallback
import com.getcapacitor.annotation.CapacitorPlugin
import com.getcapacitor.annotation.Permission
import com.getcapacitor.annotation.PermissionCallback
import org.json.JSONObject

@CapacitorPlugin(
    name = "CapacitorCalendar",
    permissions = [
        Permission(
            alias = "readCalendar",
            strings = [
                Manifest.permission.READ_CALENDAR,
            ],
        ),
        Permission(
            alias = "writeCalendar",
            strings = [
                Manifest.permission.WRITE_CALENDAR,
            ],
        ),
    ],
)
class CapacitorCalendarPlugin : Plugin() {
    private var implementation = CapacitorCalendar()
    private var currentSource = ""

    // Utils

    private fun tryCall(
        call: PluginCall,
        source: String,
        block: () -> Unit,
    ) {
        try {
            block()
        } catch (error: Exception) {
            PluginException.reject(call, error, source)
        }
    }

    private fun getNonEmptyString(
        call: PluginCall,
        param: String,
        source: String,
    ): String? {
        val value = call.getString(param)

        if (value.isNullOrEmpty()) {
            PluginException.reject(
                call,
                PluginException.ErrorType.MISSING_KEY,
                source,
                param,
            )
            return null
        } else {
            return value
        }
    }

    // Permissions

    @Throws(PluginException::class)
    private fun callHasAccess(
        call: PluginCall,
        accessType: AccessType,
        source: String,
    ): Boolean {
        val permission =
            doPermissionCheckForAlias("${accessType.name.lowercase()}Calendar", source)

        if (permission == "granted") {
            return true
        } else {
            PluginException.rejectWithNoAccess(
                call,
                EntityType.CALENDAR,
                accessType,
                source,
            )
            return false
        }
    }

    @Throws(PluginException::class)
    private fun doPermissionCheckForAlias(
        alias: String,
        source: String,
    ): String {
        return when (alias) {
            "readCalendar" -> getPermissionState(alias).toString()

            "writeCalendar" -> getPermissionState(alias).toString()

            else -> {
                throw PluginException(
                    PluginException.ErrorType.INTERNAL_ERROR,
                    source,
                    alias,
                )
            }
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun checkPermission(call: PluginCall) {
        val source = ::checkPermission.name

        tryCall(call, source) {
            val permissionName =
                getNonEmptyString(call, "alias", source)
                    ?: return@tryCall

            if (permissionName == "readCalendar" || permissionName == "writeCalendar") {
                call.resolve(JSObject().put("result", getPermissionState(permissionName)))
            } else {
                PluginException.reject(
                    call,
                    PluginException.ErrorType.INVALID_KEY,
                    source,
                    permissionName,
                )
            }
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun checkAllPermissions(call: PluginCall) {
        tryCall(call, ::checkAllPermissions.name) {
            return@tryCall checkPermissions(call)
        }
    }

    private fun doRequestPermission(
        call: PluginCall,
        alias: String,
        source: String,
    ) {
        tryCall(call, source) {
            currentSource = source
            call.data.put("alias", alias)
            return@tryCall requestPermissionForAlias(
                alias,
                call,
                "requestPermissionCallback",
            )
        }
    }

    @Throws(PluginException::class)
    @PermissionCallback
    private fun requestPermissionCallback(call: PluginCall?) {
        if (call == null) {
            throw PluginException(
                PluginException.ErrorType.INTERNAL_ERROR,
                "CapacitorCalendar.$currentSource",
                "Call is not defined",
            )
        }

        val permissionName = call.getString("alias")

        tryCall(call, currentSource) {
            call.resolve(JSObject().put("result", getPermissionState(permissionName)))
        }
    }

    @Deprecated("Use specific request<type>Permission instead")
    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun requestPermission(call: PluginCall) {
        val source = ::requestPermission.name
        val alias =
            getNonEmptyString(call, "alias", source)
                ?: return

        doRequestPermission(call, alias, source)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun requestAllPermissions(call: PluginCall) {
        tryCall(call, "CapacitorCalendar.requestAllPermissions") {
            super.requestPermissions(call)
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun requestReadOnlyCalendarAccess(call: PluginCall) {
        doRequestPermission(
            call,
            "readCalendar",
            ::requestReadOnlyCalendarAccess.name,
        )
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun requestWriteOnlyCalendarAccess(call: PluginCall) {
        doRequestPermission(
            call,
            "writeCalendar",
            ::requestReadOnlyCalendarAccess.name,
        )
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun requestFullCalendarAccess(call: PluginCall) {
        requestAllPermissions(call)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun requestFullRemindersAccess(call: PluginCall) {
        PluginException.unimplemented(call, ::requestFullRemindersAccess.name)
    }

    // Calendars

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun selectCalendarsWithPrompt(call: PluginCall) {
        PluginException.unimplemented(call, ::selectCalendarsWithPrompt.name)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun listCalendars(call: PluginCall) {
        val source = ::listCalendars.name

        tryCall(call, source) {
            if (!callHasAccess(call, AccessType.READ, source)) {
                return@tryCall
            }

            val rawAccess = call.getInt("access") ?: CapacitorCalendar.AccessMode.ALL.ordinal
            val access = CapacitorCalendar.AccessMode.fromInt(rawAccess)
            val calendars = implementation.listCalendars(context, access)
            call.resolve(JSObject().put("result", calendars))
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun getDefaultCalendar(call: PluginCall) {
        val source = ::getDefaultCalendar.name

        tryCall(call, source) {
            if (callHasAccess(
                    call,
                    AccessType.READ,
                    source,
                )
            ) {
                val primaryCalendar = implementation.getDefaultCalendar(context)
                call.resolve(JSObject().put("result", primaryCalendar ?: JSONObject.NULL))
            }
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun createCalendar(call: PluginCall) {
        PluginException.unimplemented(call, ::createCalendar.name)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun deleteCalendar(call: PluginCall) {
        PluginException.unimplemented(call, ::deleteCalendar.name)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_NONE)
    fun openCalendar(call: PluginCall) {
        val timestamp = call.getLong("date") ?: System.currentTimeMillis()

        try {
            return activity.startActivity(implementation.openCalendar(timestamp))
        } catch (error: Exception) {
            call.reject("", "[CapacitorCalendar.${::openCalendar.name}] Unable to open calendar")
        }
    }

    // Events

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun createEventWithPrompt(call: PluginCall) {
        val source = ::createEventWithPrompt.name

        tryCall(call, source) {
            if (!callHasAccess(
                    call,
                    AccessType.WRITE,
                    source,
                )
            ) {
                return@tryCall
            }

            implementation.fetchCalendarEventIDs(context)

            val title = call.getString("title", "")
            val calendarId = call.getString("calendarId")
            val location = call.getString("location")
            val startDate = call.getLong("startDate")
            val endDate = call.getLong("endDate")
            val isAllDay = call.getBoolean("isAllDay", false)

            val intent = Intent(Intent.ACTION_INSERT).setData(CalendarContract.Events.CONTENT_URI)

            intent.putExtra(CalendarContract.Events.TITLE, title)
            calendarId?.let { intent.putExtra(CalendarContract.Events.CALENDAR_ID, it) }
            location?.let { intent.putExtra(CalendarContract.Events.EVENT_LOCATION, it) }
            startDate?.let { intent.putExtra(CalendarContract.EXTRA_EVENT_BEGIN_TIME, it) }
            endDate?.let { intent.putExtra(CalendarContract.EXTRA_EVENT_END_TIME, it) }
            isAllDay?.let {
                intent.putExtra(
                    CalendarContract.EXTRA_EVENT_ALL_DAY,
                    if (it) 1 else 0,
                )
            }

            return@tryCall startActivityForResult(
                call,
                intent,
                "openCalendarIntentActivityCallback",
            )
        }
    }

    @Throws(PluginException::class)
    @ActivityCallback
    private fun openCalendarIntentActivityCallback(
        call: PluginCall?,
        result: ActivityResult,
    ) {
        if (call == null) {
            throw PluginException(
                PluginException.ErrorType.INTERNAL_ERROR,
                "CapacitorCalendar.${::createEventWithPrompt.name}",
                "call is not defined",
            )
        }

        val newEventIds =
            implementation.getNewEventIds(implementation.fetchCalendarEventIDs(context))
        val newIdsArray = JSArray()
        newEventIds.forEach { id -> newIdsArray.put(id.toString()) }
        call.resolve(JSObject().put("result", newIdsArray))
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun createEvent(call: PluginCall) {
        val source = ::createEvent.name

        tryCall(call, source) {
            if (!callHasAccess(call, AccessType.WRITE, source)) {
                return@tryCall
            }

            val title =
                getNonEmptyString(call, "title", source)
                    ?: return@tryCall
            val calendarId = call.getString("calendarId")
            val location = call.getString("location")
            val startDate = call.getLong("startDate")
            val endDate = call.getLong("endDate")
            val isAllDay = call.getBoolean("isAllDay", false)
            val alertOffsetInMinutes = call.getFloat("alertOffsetInMinutes")

            val eventUri =
                implementation.createEvent(
                    context,
                    title,
                    calendarId,
                    location,
                    startDate,
                    endDate,
                    isAllDay,
                    alertOffsetInMinutes,
                )

            val id =
                eventUri?.lastPathSegment
                    ?: throw PluginException(
                        PluginException.ErrorType.OS_ERROR,
                        source,
                        "Failed to insert event into calendar",
                    )
            call.resolve(JSObject().put("result", id))
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun listEventsInRange(call: PluginCall) {
        val source = ::listEventsInRange.name

        tryCall(call, source) {
            if (!callHasAccess(
                    call,
                    AccessType.READ,
                    source,
                )
            ) {
                return@tryCall
            }

            val startDate =
                call.getLong("startDate")
                    ?: throw PluginException(
                        PluginException.ErrorType.MISSING_KEY,
                        source,
                        "startDate",
                    )
            val endDate =
                call.getLong("endDate")
                    ?: throw PluginException(
                        PluginException.ErrorType.MISSING_KEY,
                        source,
                        "endDate",
                    )
            val ret = JSObject()
            ret.put("result", implementation.listEventsInRange(context, startDate, endDate))
            call.resolve(ret)
        }
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun deleteEventsById(call: PluginCall) {
        val source = ::deleteEventsById.name

        tryCall(call, source) {
            if (!callHasAccess(
                    call,
                    AccessType.WRITE,
                    source,
                )
            ) {
                return@tryCall
            }

            val ids =
                call.getArray("ids")
                    ?: throw PluginException(
                        PluginException.ErrorType.MISSING_KEY,
                        source,
                        "ids",
                    )
            call.resolve(JSObject().put("result", implementation.deleteEventsById(context, ids)))
        }
    }

    // Reminders

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun getDefaultRemindersList(call: PluginCall) {
        PluginException.unimplemented(call, ::getDefaultRemindersList.name)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun getRemindersLists(call: PluginCall) {
        PluginException.unimplemented(call, ::getRemindersLists.name)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun createReminder(call: PluginCall) {
        PluginException.unimplemented(call, ::createReminder.name)
    }

    @PluginMethod(returnType = PluginMethod.RETURN_PROMISE)
    fun openReminders(call: PluginCall) {
        PluginException.unimplemented(call, ::openReminders.name)
    }
}
