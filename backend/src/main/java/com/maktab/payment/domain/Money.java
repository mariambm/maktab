package com.maktab.payment.domain;

import java.math.BigDecimal;
import java.math.RoundingMode;

/** Amounts are kept to two decimals, as the database stores them, so a response never says 25 where it means 25.00. */
final class Money {

    private Money() {
    }

    static BigDecimal pounds(BigDecimal amount) {
        return amount.setScale(2, RoundingMode.UNNECESSARY);
    }
}
