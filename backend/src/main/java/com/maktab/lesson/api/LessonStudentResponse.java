package com.maktab.lesson.api;

import com.maktab.lesson.domain.AbsenceReason;
import com.maktab.lesson.domain.AttendanceStatus;
import java.util.UUID;

/** A student on the lesson's register, with their attendance when it has been recorded. */
public record LessonStudentResponse(
        UUID studentId,
        String firstName,
        String lastName,
        AttendanceStatus status,
        Integer minutesLate,
        AbsenceReason absenceReason,
        String note) {
}
