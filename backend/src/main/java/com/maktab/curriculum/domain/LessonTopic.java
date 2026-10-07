package com.maktab.curriculum.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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

    @Column(nullable = false)
    private String title;

    @Column(name = "learning_objective")
    private String learningObjective;

    @Column(name = "sort_order", nullable = false)
    private short sortOrder;

    protected LessonTopic() {
    }

    public LessonTopic(UUID curriculumWeekId, String title, String learningObjective, int sortOrder) {
        this.id = UUID.randomUUID();
        this.curriculumWeekId = curriculumWeekId;
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
