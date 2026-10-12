package com.maktab.payment.api;

import java.math.BigDecimal;
import java.time.YearMonth;
import java.util.UUID;

/** A month with its totals, counted over the students the caller may see. */
public record PaymentPeriodResponse(UUID id, YearMonth month, BigDecimal monthlyFee, String currency,
        Totals totals) {

    public record Totals(long students, long paid, long partiallyPaid, long outstanding, BigDecimal expectedTotal,
            BigDecimal paidTotal, BigDecimal outstandingTotal) {

        public static final Totals NONE = new Totals(0, 0, 0, 0, BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO);
    }
}
