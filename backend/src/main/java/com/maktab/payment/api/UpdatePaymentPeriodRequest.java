package com.maktab.payment.api;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;

public record UpdatePaymentPeriodRequest(
        @NotNull(message = "Enter the monthly fee")
        @DecimalMin(value = "0.01", message = "Enter an amount above zero")
        @Digits(integer = 6, fraction = 2, message = "Enter an amount in pounds and pence") BigDecimal monthlyFee) {
}
