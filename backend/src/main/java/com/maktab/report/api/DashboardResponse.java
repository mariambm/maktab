package com.maktab.report.api;

import com.maktab.payment.api.PaymentPeriodResponse;
import java.time.LocalDate;
import java.time.YearMonth;

/**
 * The figures on the dashboard, over the classes the caller may see: attendance of the last four weeks, targets in
 * the periods running now, and the latest month's fees for callers with payment access ({@code payments} is null
 * otherwise, or when no month has been added yet).
 */
public record DashboardResponse(Attendance attendance, Progress progress, Payments payments) {

    public record Attendance(LocalDate from, LocalDate to, Integer attendancePercentage, long late, long absent,
            int studentsBelowThreshold, int thresholdPercentage) {
    }

    public record Progress(int targets, int targetsBehind) {
    }

    public record Payments(YearMonth month, String currency, PaymentPeriodResponse.Totals totals) {
    }
}
