package com.maktab.lesson.domain;

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

/**
 * One student's attendance in one lesson. LATE carries the minutes late, ABSENT carries a reason; the database
 * enforces both rules as well.
 */
@Entity
@Table(name = "lesson_attendance")
public class LessonAttendance {

    @Id
    private UUID id;

    @Column(name = "lesson_id", nullable = false, updatable = false)
    private UUID lessonId;

    @Column(name = "student_id", nullable = false, updatable = false)
    private UUID studentId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AttendanceStatus status;

    @Column(name = "minutes_late")
    private Short minutesLate;

    @Enumerated(EnumType.STRING)
    @Column(name = "absence_reason")
    private AbsenceReason absenceReason;

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

    protected LessonAttendance() {
    }

    public LessonAttendance(UUID lessonId, UUID studentId, UUID recordedBy) {
        this.id = UUID.randomUUID();
        this.lessonId = lessonId;
        this.studentId = studentId;
        this.recordedBy = recordedBy;
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

    /** Sets the status and clears the fields that do not belong to it, so no stale minutes or reason remain. */
    public void record(AttendanceStatus status, Integer minutesLate, AbsenceReason absenceReason, String note,
            UUID recordedBy) {
        this.status = status;
        this.minutesLate = status == AttendanceStatus.LATE ? (short) (int) minutesLate : null;
        this.absenceReason = status == AttendanceStatus.ABSENT ? absenceReason : null;
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

    public AttendanceStatus getStatus() {
        return status;
    }

    public Short getMinutesLate() {
        return minutesLate;
    }

    public AbsenceReason getAbsenceReason() {
        return absenceReason;
    }

    public String getNote() {
        return note;
    }

    public UUID getRecordedBy() {
        return recordedBy;
    }
}
