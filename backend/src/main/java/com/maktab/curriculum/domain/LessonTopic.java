package com.maktab.curriculum.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.util.UUID;

/** A topic and its learning objective within a curriculum week. Lessons record which topics they covered. */
@Entity
@Table(name = "lesson_topic")
public class LessonTopic {

    @Id
    private UUID id;

    @Column(name = "curriculum_week_id", nullable = false, updatable = false)
    private UUID curriculumWeekId;

    /** Null only for topics written before subjects existed. */
    @Enumerated(EnumType.STRING)
    @Column
    private Subject subject;

    @Column(nullable = false)
    private String title;

    @Column(name = "learning_objective")
    private String learningObjective;

    @Column(name = "sort_order", nullable = false)
    private short sortOrder;

    protected LessonTopic() {
    }

    public LessonTopic(UUID curriculumWeekId, Subject subject, String title, String learningObjective,
            int sortOrder) {
        this.id = UUID.randomUUID();
        this.curriculumWeekId = curriculumWeekId;
        this.subject = subject;
        this.title = title;
        this.learningObjective = learningObjective;
        this.sortOrder = (short) sortOrder;
    }

    public UUID getId() {
        return id;
    }

    public UUID getCurriculumWeekId() {
        return curriculumWeekId;
    }

    public Subject getSubject() {
        return subject;
    }

    public String getTitle() {
        return title;
    }

    public String getLearningObjective() {
        return learningObjective;
    }

    public short getSortOrder() {
        return sortOrder;
    }
}
