package com.maktab.curriculum.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

/** One of the four weeks in a period. Week 4 is a review / assessment week by default. */
@Entity
@Table(name = "curriculum_week")
public class CurriculumWeek {

    /** The week that is a review week when a period is created. */
    public static final int REVIEW_WEEK = 4;

    @Id
    private UUID id;

    @Column(name = "curriculum_period_id", nullable = false, updatable = false)
    private UUID curriculumPeriodId;

    @Column(name = "week_number", nullable = false, updatable = false)
    private short weekNumber;

    @Column(name = "is_review", nullable = false)
    private boolean review;

    protected CurriculumWeek() {
    }

    public CurriculumWeek(UUID curriculumPeriodId, int weekNumber, boolean review) {
        this.id = UUID.randomUUID();
        this.curriculumPeriodId = curriculumPeriodId;
        this.weekNumber = (short) weekNumber;
        this.review = review;
    }

    public void setReview(boolean review) {
        this.review = review;
    }

    public UUID getId() {
        return id;
    }

    public UUID getCurriculumPeriodId() {
        return curriculumPeriodId;
    }

    public short getWeekNumber() {
        return weekNumber;
    }

    public boolean isReview() {
        return review;
    }
}
