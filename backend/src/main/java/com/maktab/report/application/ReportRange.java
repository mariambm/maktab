package com.maktab.report.application;

import com.maktab.common.BusinessValidationException;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

/** The dates a report covers. Without dates a report covers the last four weeks, today included. */
public record ReportRange(LocalDate from, LocalDate to) {

    static final int DEFAULT_DAYS = 28;
    static final int MAX_DAYS = 366;

    public static ReportRange of(LocalDate from, LocalDate to, LocalDate today) {
        LocalDate end = to == null ? today : to;
        LocalDate start = from == null ? end.minusDays(DEFAULT_DAYS - 1) : from;
        if (start.isAfter(end)) {
            throw new BusinessValidationException("from", "The start date must be on or before the end date");
        }
        if (ChronoUnit.DAYS.between(start, end) >= MAX_DAYS) {
            throw new BusinessValidationException("from", "Choose a period of at most a year");
        }
        return new ReportRange(start, end);
    }

    public static ReportRange lastFourWeeks(LocalDate today) {
        return of(null, null, today);
    }
}
