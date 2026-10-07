package com.maktab.lesson.api;

import com.maktab.lesson.domain.AbsenceReason;
import com.maktab.lesson.domain.AttendanceStatus;
import com.maktab.lesson.domain.LessonAttendance;
import java.util.UUID;

public record AttendanceResponse(
        UUID studentId,
        AttendanceStatus status,
        Integer minutesLate,
        AbsenceReason absenceReason,
        String note) {

    public static AttendanceResponse from(LessonAttendance attendance) {
        return new AttendanceResponse(attendance.getStudentId(), attendance.getStatus(),
                attendance.getMinutesLate() == null ? null : (int) attendance.getMinutesLate(),
                attendance.getAbsenceReason(), attendance.getNote());
    }
}
