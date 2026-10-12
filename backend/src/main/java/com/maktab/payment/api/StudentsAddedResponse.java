package com.maktab.payment.api;

/** How many students were added to a month, and the month's totals afterwards. */
public record StudentsAddedResponse(int added, PaymentPeriodResponse period) {
}
