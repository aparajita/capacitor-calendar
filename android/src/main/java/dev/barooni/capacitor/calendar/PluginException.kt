package dev.barooni.capacitor.calendar

import com.getcapacitor.JSObject
import com.getcapacitor.PluginCall

class PluginException
(type: ErrorType, source: String, data: String? = null) : Exception() {
    enum class ErrorType(val value: String) {
        MISSING_KEY("missingKey"),
        INVALID_KEY("invalidKey"),
        NO_ACCESS("noAccess"),
        CALENDAR_NOT_FOUND("calendarNotFound"),
        NO_DEFAULT_CALENDAR("noDefaultCalendar"),
        UNABLE_TO_OPEN_CALENDAR("unableToOpenCalendar"),
        UNABLE_TO_OPEN_REMINDERS("unableToOpenReminders"),
        NO_VIEW_CONTROLLER("noViewController"),
        OS_ERROR("osError"),
        UNIMPLEMENTED("unimplemented"),
        INTERNAL_ERROR("internalError"),
        UNKNOWN_ERROR("unknownError"),
    }

    private val errorMessages: Map<ErrorType, String> =
        mapOf(
            ErrorType.MISSING_KEY to "Empty or missing key",
            ErrorType.INVALID_KEY to "Invalid value for key",
            ErrorType.NO_ACCESS to "Access has not been granted",
            ErrorType.CALENDAR_NOT_FOUND to "Calendar with the given id not found",
            ErrorType.NO_DEFAULT_CALENDAR to "No default calendar is available",
            ErrorType.UNABLE_TO_OPEN_CALENDAR to "The calendar app could not be opened",
            ErrorType.UNABLE_TO_OPEN_REMINDERS to "The reminders app could not be opened",
            ErrorType.NO_VIEW_CONTROLLER to "View controller could not be created",
            ErrorType.OS_ERROR to "An iOS error has occurred",
            ErrorType.UNIMPLEMENTED to "Not implemented on Android",
            ErrorType.UNKNOWN_ERROR to "An unknown error occurred",
        )

    override var message = ""
    private var type = ""

    init {
        this.type = type.value
        val msg = errorMessages[type]

        if (msg != null) {
            message = msg

            when (type) {
                ErrorType.MISSING_KEY,
                ErrorType.INVALID_KEY,
                -> {
                    if (data != null) {
                        message += " $data"
                    }
                }

                ErrorType.NO_ACCESS -> {
                    if (data != null) {
                        message += " ($data)"
                    }
                }

                ErrorType.INTERNAL_ERROR,
                ErrorType.OS_ERROR,
                ErrorType.UNKNOWN_ERROR,
                -> {
                    if (data != null) {
                        message += ": $data"
                    }
                }

                else -> {}
            }
        } else {
            // We know this value exists, so we can safely use the !! operator
            message = errorMessages[ErrorType.UNKNOWN_ERROR]!!
        }

        message = "[CapacitorCalendar.$source] $message"
    }

    constructor(fromError: Exception, source: String) : this(ErrorType.OS_ERROR, source, null) {
        message =
            when (fromError) {
                is PluginException -> {
                    "[CapacitorCalendar.$source] $fromError.message"
                }

                else -> {
                    "[CapacitorCalendar.$source] ${fromError.localizedMessage}"
                }
            }
    }

    fun reject(call: PluginCall) {
        call.reject(message, null, null, JSObject().put("type", type))
    }

    companion object {
        fun reject(
            call: PluginCall,
            type: ErrorType,
            source: String,
            data: String? = null,
        ) {
            PluginException(type, source, data).reject(call)
        }

        fun reject(
            call: PluginCall,
            error: Exception,
            source: String,
        ) {
            when (error) {
                is PluginException -> {
                    error.reject(call)
                }

                else -> {
                    reject(call, ErrorType.OS_ERROR, source, error.localizedMessage)
                }
            }
        }

        private fun noAccessForEntity(
            entityType: EntityType,
            accessType: AccessType,
            source: String,
        ): PluginException {
            return PluginException(
                ErrorType.NO_ACCESS,
                source,
                "${entityType.name.lowercase()}/${accessType.name.lowercase()}",
            )
        }

        fun rejectWithNoAccess(
            call: PluginCall,
            entityType: EntityType,
            accessType: AccessType,
            source: String,
        ) {
            noAccessForEntity(entityType, accessType, source).reject(call)
        }

        fun unimplemented(
            call: PluginCall,
            source: String,
        ) {
            PluginException(ErrorType.UNIMPLEMENTED, source).reject(call)
        }
    }
}
