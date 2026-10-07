package com.maktab.lesson.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.util.List;

/** The whole register for a lesson, saved in one request. */
public record RecordAttendanceRequest(@NotNull(message = "Attendance is required") List<@Valid AttendanceEntryRequest> entries) {
}
