package com.maktab.report.api;

import com.maktab.payment.api.PaymentPeriodResponse;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/** Fees over the most recent months: each month's totals, the sum of them, and who still owes money. */
public record PaymentReportResponse(String currency, List<PaymentPeriodResponse> months,
        PaymentPeriodResponse.Totals totals, List<Owing> studentsOwing) {

    public record Owing(UUID studentId, String firstName, String lastName, String className, long months,
            BigDecimal outstandingAmount) {
    }
}
