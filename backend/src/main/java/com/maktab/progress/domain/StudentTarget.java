package com.maktab.progress.domain;

import com.maktab.curriculum.domain.Subject;
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
import java.util.UUID;

/** What a student works towards in one four-week period, with where they stand now. */
@Entity
@Table(name = "student_target")
public class StudentTarget {

    @Id
    private UUID id;

    @Column(name = "student_id", nullable = false, updatable = false)
    private UUID studentId;

    @Column(name = "curriculum_period_id", nullable = false, updatable = false)
    private UUID curriculumPeriodId;

    @Enumerated(EnumType.STRING)
    @Column
    private Subject subject;

    @Column(nullable = false)
    private String description;

    @Column(name = "target_percentage")
    private Short targetPercentage;

    @Column(name = "current_percentage")
    private Short currentPercentage;

    @Column(name = "progress_score")
    private BigDecimal progressScore;

    @Column(name = "teacher_note")
    private String teacherNote;

    @Column(name = "created_by", nullable = false, updatable = false)
    private UUID createdBy;

    @Column(name = "updated_by", nullable = false)
    private UUID updatedBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private long version;

    protected StudentTarget() {
    }

    public StudentTarget(UUID studentId, UUID curriculumPeriodId, UUID createdBy) {
        this.id = UUID.randomUUID();
        this.studentId = studentId;
        this.curriculumPeriodId = curriculumPeriodId;
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

    public void update(Subject subject, String description, Integer targetPercentage, Integer currentPercentage,
            BigDecimal progressScore, String teacherNote, UUID updatedBy) {
        this.subject = subject;
        this.description = description;
        this.targetPercentage = targetPercentage == null ? null : targetPercentage.shortValue();
        this.currentPercentage = currentPercentage == null ? null : currentPercentage.shortValue();
        this.progressScore = progressScore;
        this.teacherNote = teacherNote;
        this.updatedBy = updatedBy;
    }

    public UUID getId() {
        return id;
    }

    public UUID getStudentId() {
        return studentId;
    }

    public UUID getCurriculumPeriodId() {
        return curriculumPeriodId;
    }

    public Subject getSubject() {
        return subject;
    }

    public String getDescription() {
        return description;
    }

    public Short getTargetPercentage() {
        return targetPercentage;
    }

    public Short getCurrentPercentage() {
        return currentPercentage;
    }

    public BigDecimal getProgressScore() {
        return progressScore;
    }

    public String getTeacherNote() {
        return teacherNote;
    }
}
