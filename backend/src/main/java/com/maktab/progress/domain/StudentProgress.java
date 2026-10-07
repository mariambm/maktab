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

/** A student's score for one subject in one lesson. */
@Entity
@Table(name = "student_progress")
public class StudentProgress {

    @Id
    private UUID id;

    @Column(name = "lesson_id", nullable = false, updatable = false)
    private UUID lessonId;

    @Column(name = "student_id", nullable = false, updatable = false)
    private UUID studentId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, updatable = false)
    private Subject subject;

    @Column(nullable = false)
    private BigDecimal score;

    @Column
    private String note;

    @Column(name = "recorded_by", nullable = false)
    private UUID recordedBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private long version;

    protected StudentProgress() {
    }

    public StudentProgress(UUID lessonId, UUID studentId, Subject subject) {
        this.id = UUID.randomUUID();
        this.lessonId = lessonId;
        this.studentId = studentId;
        this.subject = subject;
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

    public void record(BigDecimal score, String note, UUID recordedBy) {
        this.score = score;
        this.note = note;
        this.recordedBy = recordedBy;
    }

    public UUID getId() {
        return id;
    }

    public UUID getLessonId() {
        return lessonId;
    }

    public UUID getStudentId() {
        return studentId;
    }

    public Subject getSubject() {
        return subject;
    }

    public BigDecimal getScore() {
        return score;
    }

    public String getNote() {
        return note;
    }
}
