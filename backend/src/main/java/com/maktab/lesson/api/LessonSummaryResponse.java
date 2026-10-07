package com.maktab.lesson.api;

import com.maktab.lesson.domain.LessonStatus;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * A lesson in a list or on "Today". {@code id} is null for a scheduled slot that has not been opened yet; opening
 * it creates the lesson.
 */
public record LessonSummaryResponse(
        UUID id,
        UUID classGroupId,
        String className,
        String room,
        LocalDate lessonDate,
        LocalTime startTime,
        LocalTime endTime,
        LessonStatus status,
        UUID classScheduleId,
        long studentCount,
        long attendanceRecorded) {

    public boolean isOpened() {
        return id != null;
    }
}
