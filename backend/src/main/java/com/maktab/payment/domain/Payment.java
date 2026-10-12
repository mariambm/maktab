package com.maktab.payment.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/** What one student owes for one month and what has been received. */
@Entity
@Table(name = "payment")
public class Payment {

    @Id
    private UUID id;

    @Column(name = "payment_period_id", nullable = false, updatable = false)
    private UUID paymentPeriodId;

    @Column(name = "student_id", nullable = false, updatable = false)
    private UUID studentId;

    @Column(name = "parent_guardian_id")
    private UUID parentGuardianId;

    @Column(name = "expected_amount", nullable = false)
    private BigDecimal expectedAmount;

    @Column(name = "amount_paid", nullable = false)
    private BigDecimal amountPaid;

    @Column(name = "paid_on")
    private LocalDate paidOn;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_method")
    private PaymentMethod method;

    @Column
    private String note;

    @Column(name = "updated_by")
    private UUID updatedBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private long version;

    protected Payment() {
    }

    public Payment(UUID paymentPeriodId, UUID studentId, UUID parentGuardianId, BigDecimal expectedAmount) {
        this.id = UUID.randomUUID();
        this.paymentPeriodId = paymentPeriodId;
        this.studentId = studentId;
        this.parentGuardianId = parentGuardianId;
        this.expectedAmount = Money.pounds(expectedAmount);
        this.amountPaid = Money.pounds(BigDecimal.ZERO);
    }

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    /** Nothing received clears the date and method, as the database requires. */
    public void update(BigDecimal expectedAmount, BigDecimal amountPaid, LocalDate paidOn, PaymentMethod method,
            UUID parentGuardianId, String note, UUID updatedBy) {
        boolean received = amountPaid.signum() > 0;
        this.expectedAmount = Money.pounds(expectedAmount);
        this.amountPaid = Money.pounds(amountPaid);
        this.paidOn = received ? paidOn : null;
        this.method = received ? method : null;
        this.parentGuardianId = parentGuardianId;
        this.note = note;
        this.updatedBy = updatedBy;
    }

    public void changeExpectedAmount(BigDecimal expectedAmount) {
        this.expectedAmount = Money.pounds(expectedAmount);
    }

    public PaymentStatus getStatus() {
        return PaymentStatus.of(expectedAmount, amountPaid);
    }

    public BigDecimal getOutstandingAmount() {
        return expectedAmount.subtract(amountPaid).max(BigDecimal.ZERO);
    }

    public UUID getId() {
        return id;
    }

    public UUID getPaymentPeriodId() {
        return paymentPeriodId;
    }

    public UUID getStudentId() {
        return studentId;
    }

    public UUID getParentGuardianId() {
        return parentGuardianId;
    }

    public BigDecimal getExpectedAmount() {
        return expectedAmount;
    }

    public BigDecimal getAmountPaid() {
        return amountPaid;
    }

    public LocalDate getPaidOn() {
        return paidOn;
    }

    public PaymentMethod getMethod() {
        return method;
    }

    public String getNote() {
        return note;
    }
}
