package com.maktab.report.api;

import com.maktab.lesson.domain.AbsenceReason;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * Attendance over a date range: the totals, each class, and the students whose attendance is below the mosque's
 * threshold. A percentage counts present and late as attended; it is null when no register was taken.
 */
public record AttendanceReportResponse(
        LocalDate from,
        LocalDate to,
        int thresholdPercentage,
        Counts totals,
        Map<AbsenceReason, Long> absenceReasons,
        List<ClassRow> classes,
        List<StudentRow> belowThreshold) {

    public record Counts(long lessons, long records, long present, long late, long absent,
            Integer attendancePercentage) {
    }

    public record ClassRow(UUID classId, String className, Counts counts) {
    }

    public record StudentRow(UUID studentId, String firstName, String lastName, UUID classId, String className,
            Counts counts) {
    }
}
