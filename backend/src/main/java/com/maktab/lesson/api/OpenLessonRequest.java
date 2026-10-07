package com.maktab.lesson.api;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * Opens the lesson for a class on a date, creating it the first time. With a {@code classScheduleId} the times come
 * from that weekly slot; otherwise both times are required.
 */
public record OpenLessonRequest(
        @NotNull(message = "Class is required") UUID classGroupId,
        @NotNull(message = "Date is required") LocalDate lessonDate,
        UUID classScheduleId,
        LocalTime startTime,
        LocalTime endTime) {
}
