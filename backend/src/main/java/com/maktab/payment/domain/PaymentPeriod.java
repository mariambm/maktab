package com.maktab.payment.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.UUID;

/** One calendar month of fees, with the amount each student is expected to pay for it. */
@Entity
@Table(name = "payment_period")
public class PaymentPeriod {

    @Id
    private UUID id;

    @Column(name = "organisation_id", nullable = false, updatable = false)
    private UUID organisationId;

    /** The first day of the month. */
    @Column(nullable = false, updatable = false)
    private LocalDate month;

    @Column(name = "monthly_fee", nullable = false)
    private BigDecimal monthlyFee;

    @Column(name = "created_by", nullable = false, updatable = false)
    private UUID createdBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private long version;

    protected PaymentPeriod() {
    }

    public PaymentPeriod(UUID organisationId, YearMonth month, BigDecimal monthlyFee, UUID createdBy) {
        this.id = UUID.randomUUID();
        this.organisationId = organisationId;
        this.month = month.atDay(1);
        this.monthlyFee = Money.pounds(monthlyFee);
        this.createdBy = createdBy;
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

    public void changeFee(BigDecimal monthlyFee) {
        this.monthlyFee = Money.pounds(monthlyFee);
    }

    public UUID getId() {
        return id;
    }

    public UUID getOrganisationId() {
        return organisationId;
    }

    public YearMonth getMonth() {
        return YearMonth.from(month);
    }

    public BigDecimal getMonthlyFee() {
        return monthlyFee;
    }
}
