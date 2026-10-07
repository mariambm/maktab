package com.maktab.lesson.api;

/**
 * Attendance figures, calculated on request and never stored. {@code attendancePercentage} counts PRESENT and LATE
 * as attended; it is null when there are no records yet.
 */
public record AttendanceStatisticsResponse(
        long lessons,
        long present,
        long late,
        long absent,
        Integer attendancePercentage,
        int threshold,
        boolean belowThreshold) {
}
