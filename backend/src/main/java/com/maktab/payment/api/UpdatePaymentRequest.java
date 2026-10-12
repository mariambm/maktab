package com.maktab.payment.api;

import com.maktab.payment.domain.PaymentMethod;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * One student's payment for a month. {@code amountPaid} is the total received for that month; when it is above
 * zero the date and method are required, and when it is zero they are cleared.
 */
public record UpdatePaymentRequest(
        @NotNull(message = "Enter the amount expected")
        @DecimalMin(value = "0.01", message = "Enter an amount above zero")
        @Digits(integer = 6, fraction = 2, message = "Enter an amount in pounds and pence") BigDecimal expectedAmount,
        @NotNull(message = "Enter the amount paid")
        @DecimalMin(value = "0.00", message = "Enter zero or more")
        @Digits(integer = 6, fraction = 2, message = "Enter an amount in pounds and pence") BigDecimal amountPaid,
        LocalDate paidOn,
        PaymentMethod method,
        UUID parentGuardianId,
        @Size(max = 500, message = "Note is too long") String note) {
}
