package com.maktab.curriculum.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * A four-week teaching period for one curriculum level, for example "Period 3". The end date is the last day of
 * week 4, so a period always spans 28 days.
 */
@Entity
@Table(name = "curriculum_period")
public class CurriculumPeriod {

    /** A period is four weeks; the end date is the last day of the fourth week. */
    public static final int LENGTH_IN_DAYS = 28;

    @Id
    private UUID id;

    @Column(name = "curriculum_level_id", nullable = false, updatable = false)
    private UUID curriculumLevelId;

    @Column(nullable = false, updatable = false)
    private short number;

    @Column(nullable = false)
    private String name;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private long version;

    protected CurriculumPeriod() {
    }

    public CurriculumPeriod(UUID curriculumLevelId, int number, String name, LocalDate startDate) {
        this.id = UUID.randomUUID();
        this.curriculumLevelId = curriculumLevelId;
        this.number = (short) number;
        this.name = name;
        setStartDate(startDate);
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

    public void update(String name, LocalDate startDate) {
        this.name = name;
        setStartDate(startDate);
    }

    private void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
        this.endDate = startDate.plusDays(LENGTH_IN_DAYS - 1L);
    }

    /** Which of the four weeks {@code date} falls in, or empty when the date is outside this period. */
    public java.util.Optional<Integer> weekNumberOn(LocalDate date) {
        if (date.isBefore(startDate) || date.isAfter(endDate)) {
            return java.util.Optional.empty();
        }
        return java.util.Optional.of((int) (java.time.temporal.ChronoUnit.DAYS.between(startDate, date) / 7 + 1));
    }

    public UUID getId() {
        return id;
    }

    public UUID getCurriculumLevelId() {
        return curriculumLevelId;
    }

    public short getNumber() {
        return number;
    }

    public String getName() {
        return name;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }
}
