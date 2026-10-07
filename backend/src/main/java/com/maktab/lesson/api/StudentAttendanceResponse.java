package com.maktab.lesson.api;

import com.maktab.lesson.domain.AbsenceReason;
import com.maktab.lesson.domain.AttendanceStatus;
import java.time.LocalDate;
import java.util.UUID;

/** One attendance row in a student's history. */
public record StudentAttendanceResponse(
        UUID lessonId,
        LocalDate lessonDate,
        UUID classGroupId,
        String className,
        AttendanceStatus status,
        Integer minutesLate,
        AbsenceReason absenceReason,
        String note) {
}
