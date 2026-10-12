package com.maktab.payment.domain;

import java.math.BigDecimal;

/** Worked out from the amounts every time it is needed; never stored. */
public enum PaymentStatus {
    PAID,
    PARTIALLY_PAID,
    OUTSTANDING;

    public static PaymentStatus of(BigDecimal expected, BigDecimal paid) {
        if (paid.signum() == 0) {
            return OUTSTANDING;
        }
        return paid.compareTo(expected) >= 0 ? PAID : PARTIALLY_PAID;
    }
}
