package com.maktab.payment.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.common.PageResponse;
import com.maktab.payment.application.PaymentService;
import com.maktab.payment.domain.PaymentStatus;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PaymentController {

    private final PaymentService payments;

    public PaymentController(PaymentService payments) {
        this.payments = payments;
    }

    @GetMapping("/api/payment-periods")
    @PreAuthorize("hasAuthority('PAYMENT_READ')")
    public List<PaymentPeriodResponse> periods(@AuthenticationPrincipal CurrentUser currentUser) {
        return payments.periods(currentUser);
    }

    @GetMapping("/api/payment-periods/{id}")
    @PreAuthorize("hasAuthority('PAYMENT_READ')")
    public PaymentPeriodResponse period(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id) {
        return payments.period(currentUser, id);
    }

    @PostMapping("/api/payment-periods")
    @PreAuthorize("hasAuthority('PAYMENT_WRITE')")
    @ResponseStatus(HttpStatus.CREATED)
    public PaymentPeriodResponse createPeriod(@AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody CreatePaymentPeriodRequest request) {
        return payments.createPeriod(currentUser, request);
    }

    @PutMapping("/api/payment-periods/{id}")
    @PreAuthorize("hasAuthority('PAYMENT_WRITE')")
    public PaymentPeriodResponse changeFee(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody UpdatePaymentPeriodRequest request) {
        return payments.changeFee(currentUser, id, request);
    }

    /** Adds students who joined after the month was added. */
    @PostMapping("/api/payment-periods/{id}/payments")
    @PreAuthorize("hasAuthority('PAYMENT_WRITE')")
    public StudentsAddedResponse addNewStudents(@AuthenticationPrincipal CurrentUser currentUser,
            @PathVariable UUID id) {
        return payments.addNewStudents(currentUser, id);
    }

    @GetMapping("/api/payments")
    @PreAuthorize("hasAuthority('PAYMENT_READ')")
    public PageResponse<PaymentResponse> search(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) UUID periodId,
            @RequestParam(required = false) UUID studentId,
            @RequestParam(required = false) PaymentStatus status,
            @RequestParam(required = false) UUID classId,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "50") @Min(1) @Max(200) int size) {
        return payments.search(currentUser, periodId, studentId, status, classId, search, page, size);
    }

    @PutMapping("/api/payments/{id}")
    @PreAuthorize("hasAuthority('PAYMENT_WRITE')")
    public PaymentResponse update(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody UpdatePaymentRequest request) {
        return payments.update(currentUser, id, request);
    }

    @DeleteMapping("/api/payments/{id}")
    @PreAuthorize("hasAuthority('PAYMENT_WRITE')")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id) {
        payments.remove(currentUser, id);
    }
}
