package com.maktab.report.application;

import com.maktab.lesson.domain.AttendanceStatus;
import com.maktab.report.api.AttendanceReportResponse.Counts;
import java.math.BigDecimal;
import java.math.RoundingMode;

/** The small calculations every report shares, so a percentage or an average means the same thing everywhere. */
final class Figures {

    private Figures() {
    }

    /** Present and late count as attended. Null when there is nothing to divide by. */
    static Integer attendancePercentage(long present, long late, long absent) {
        long records = present + late + absent;
        return records == 0 ? null : (int) Math.round((present + late) * 100.0 / records);
    }

    /** An average score shown with one decimal, as the scale itself goes in halves. */
    static BigDecimal averageScore(Double average) {
        return average == null ? null : BigDecimal.valueOf(average).setScale(1, RoundingMode.HALF_UP);
    }

    /** Running attendance counts for one class or student. */
    static final class Tally {

        long present;
        long late;
        long absent;
        long lessons;

        void add(AttendanceStatus status, long total) {
            switch (status) {
                case PRESENT -> present += total;
                case LATE -> late += total;
                case ABSENT -> absent += total;
            }
        }

        Integer percentage() {
            return attendancePercentage(present, late, absent);
        }

        Counts counts() {
            return new Counts(lessons, present + late + absent, present, late, absent, percentage());
        }
    }
}
