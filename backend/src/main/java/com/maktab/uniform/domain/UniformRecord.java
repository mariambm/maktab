package com.maktab.uniform.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

/** A student's uniform as seen in one lesson. */
@Entity
@Table(name = "uniform_record")
public class UniformRecord {

    @Id
    private UUID id;

    @Column(name = "lesson_id", nullable = false, updatable = false)
    private UUID lessonId;

    @Column(name = "student_id", nullable = false, updatable = false)
    private UUID studentId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private UniformStatus status;

    @Enumerated(EnumType.STRING)
    @Column
    private UniformReason reason;

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

    protected UniformRecord() {
    }

    public UniformRecord(UUID lessonId, UUID studentId) {
        this.id = UUID.randomUUID();
        this.lessonId = lessonId;
        this.studentId = studentId;
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

    /** Uniform in order never keeps a reason, as the database also enforces. */
    public void record(UniformStatus status, UniformReason reason, String note, UUID recordedBy) {
        this.status = status;
        this.reason = status == UniformStatus.IN_ORDER ? null : reason;
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

    public UniformStatus getStatus() {
        return status;
    }

    public UniformReason getReason() {
        return reason;
    }

    public String getNote() {
        return note;
    }
}
