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
 * A student's membership of a class from {@code startDate} up to, not including, {@code endDate}. Moving a student
 * closes the open enrolment and opens a new one, so class history is never overwritten.
 */
@Entity
@Table(name = "class_enrollment")
public class ClassEnrollment {

    @Id
    private UUID id;

    @Column(name = "student_id", nullable = false, updatable = false)
    private UUID studentId;

    @Column(name = "class_group_id", nullable = false, updatable = false)
    private UUID classGroupId;

    @Column(name = "start_date", nullable = false, updatable = false)
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected ClassEnrollment() {
    }

    public ClassEnrollment(UUID studentId, UUID classGroupId, LocalDate startDate) {
        this.id = UUID.randomUUID();
        this.studentId = studentId;
        this.classGroupId = classGroupId;
        this.startDate = startDate;
    }

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
    }

    public void end(LocalDate date) {
        this.endDate = date;
    }

    public boolean isOpen() {
        return endDate == null;
    }

    public UUID getId() {
        return id;
    }

    public UUID getStudentId() {
        return studentId;
    }

    public UUID getClassGroupId() {
        return classGroupId;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }
}
