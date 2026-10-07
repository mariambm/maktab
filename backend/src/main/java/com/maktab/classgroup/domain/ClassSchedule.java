package com.maktab.classgroup.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.UUID;

/** A weekly slot in which a class meets. Replaced as a whole when the schedule changes. */
@Entity
@Table(name = "class_schedule")
public class ClassSchedule {

    @Id
    private UUID id;

    @Column(name = "class_group_id", nullable = false, updatable = false)
    private UUID classGroupId;

    /** ISO weekday, 1 = Monday. */
    @Column(nullable = false)
    private short weekday;

    @Column(name = "start_time", nullable = false)
    private LocalTime startTime;

    @Column(name = "end_time", nullable = false)
    private LocalTime endTime;

    protected ClassSchedule() {
    }

    public ClassSchedule(UUID classGroupId, DayOfWeek weekday, LocalTime startTime, LocalTime endTime) {
        this.id = UUID.randomUUID();
        this.classGroupId = classGroupId;
        this.weekday = (short) weekday.getValue();
        this.startTime = startTime;
        this.endTime = endTime;
    }

    public UUID getId() {
        return id;
    }

    public UUID getClassGroupId() {
        return classGroupId;
    }

    public DayOfWeek getWeekday() {
        return DayOfWeek.of(weekday);
    }

    public LocalTime getStartTime() {
        return startTime;
    }

    public LocalTime getEndTime() {
        return endTime;
    }
}
