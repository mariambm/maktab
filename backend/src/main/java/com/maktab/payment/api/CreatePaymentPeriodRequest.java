package com.maktab.payment.api;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.YearMonth;

/** Opens a month, for example {@code {"month":"2026-11","monthlyFee":25.00}}. */
public record CreatePaymentPeriodRequest(
        @NotNull(message = "Choose a month") YearMonth month,
        @NotNull(message = "Enter the monthly fee")
        @DecimalMin(value = "0.01", message = "Enter an amount above zero")
        @Digits(integer = 6, fraction = 2, message = "Enter an amount in pounds and pence") BigDecimal monthlyFee) {
}
