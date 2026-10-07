package com.maktab.classgroup.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;
import java.time.Instant;
import java.time.LocalDate;
import java.util.UUID;

/**
 * A teacher's assignment to a class over a period. The open assignment (no end date) is what gives a teacher access
 * to the class and its students. Ending an assignment closes the row instead of deleting it.
 */
@Entity
@Table(name = "class_teacher")
public class ClassTeacher {

    @Id
    private UUID id;

    @Column(name = "class_group_id", nullable = false, updatable = false)
    private UUID classGroupId;

    @Column(name = "teacher_user_id", nullable = false, updatable = false)
    private UUID teacherUserId;

    @Column(name = "start_date", nullable = false, updatable = false)
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected ClassTeacher() {
    }

    public ClassTeacher(UUID classGroupId, UUID teacherUserId, LocalDate startDate) {
        this.id = UUID.randomUUID();
        this.classGroupId = classGroupId;
        this.teacherUserId = teacherUserId;
        this.startDate = startDate;
    }

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
    }

    /** Ends the assignment on {@code date} (exclusive); an assignment that never started ends on its start date. */
    public void end(LocalDate date) {
        this.endDate = date.isBefore(startDate) ? startDate : date;
    }

    public UUID getId() {
        return id;
    }

    public UUID getClassGroupId() {
        return classGroupId;
    }

    public UUID getTeacherUserId() {
        return teacherUserId;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }
}
