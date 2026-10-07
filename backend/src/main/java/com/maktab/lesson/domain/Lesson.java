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
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.UUID;

/**
 * One meeting of a class on one date. Created the first time a teacher opens a scheduled slot, or by hand for a
 * lesson outside the weekly schedule.
 */
@Entity
@Table(name = "lesson")
public class Lesson {

    @Id
    private UUID id;

    @Column(name = "class_group_id", nullable = false, updatable = false)
    private UUID classGroupId;

    /** The weekly slot this lesson came from, when it has one. */
    @Column(name = "class_schedule_id")
    private UUID classScheduleId;

    @Column(name = "lesson_date", nullable = false, updatable = false)
    private LocalDate lessonDate;

    @Column(name = "start_time", nullable = false, updatable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    @Column(name = "teacher_user_id", nullable = false)
    private UUID teacherUserId;

    @Column(name = "content_notes")
    private String contentNotes;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LessonStatus status = LessonStatus.PLANNED;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private long version;

    protected Lesson() {
    }

    public Lesson(UUID classGroupId, UUID classScheduleId, LocalDate lessonDate, LocalTime startTime,
            LocalTime endTime, UUID teacherUserId) {
        this.id = UUID.randomUUID();
        this.classGroupId = classGroupId;
        this.classScheduleId = classScheduleId;
        this.lessonDate = lessonDate;
        this.startTime = startTime;
        this.endTime = endTime;
        this.teacherUserId = teacherUserId;
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

    public void update(LocalTime endTime, String contentNotes, LessonStatus status, UUID teacherUserId) {
        this.endTime = endTime;
        this.contentNotes = contentNotes;
        this.status = status;
        this.teacherUserId = teacherUserId;
    }

    public UUID getId() {
        return id;
    }

    public UUID getClassGroupId() {
        return classGroupId;
    }

    public UUID getClassScheduleId() {
        return classScheduleId;
    }

    public LocalDate getLessonDate() {
        return lessonDate;
    }

    public LocalTime getStartTime() {
        return startTime;
    }

    public LocalTime getEndTime() {
        return endTime;
    }

    public UUID getTeacherUserId() {
        return teacherUserId;
    }

    public String getContentNotes() {
        return contentNotes;
    }

    public LessonStatus getStatus() {
        return status;
    }
}
