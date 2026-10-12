package com.maktab.payment.api;

import com.maktab.payment.domain.PaymentMethod;
import com.maktab.payment.domain.PaymentStatus;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.UUID;

public record PaymentResponse(UUID id, UUID periodId, YearMonth month, UUID studentId, String firstName,
        String lastName, String className, Payer payer, BigDecimal expectedAmount, BigDecimal amountPaid,
        BigDecimal outstandingAmount, String currency, PaymentStatus status, LocalDate paidOn, PaymentMethod method, String note) {

    /** The parent or guardian who pays for the student. */
    public record Payer(UUID id, String firstName, String lastName) {
    }
}
