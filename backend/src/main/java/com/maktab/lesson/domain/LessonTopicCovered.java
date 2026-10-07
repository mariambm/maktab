package com.maktab.lesson.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

/** Link between a lesson and a curriculum topic it covered. */
@Entity
@Table(name = "lesson_topic_covered")
public class LessonTopicCovered {

    @EmbeddedId
    private Id id;

    protected LessonTopicCovered() {
    }

    public LessonTopicCovered(UUID lessonId, UUID lessonTopicId) {
        this.id = new Id(lessonId, lessonTopicId);
    }

    public UUID getLessonId() {
        return id.lessonId;
    }

    public UUID getLessonTopicId() {
        return id.lessonTopicId;
    }

    @Embeddable
    public static class Id implements Serializable {

        @Column(name = "lesson_id", nullable = false)
        private UUID lessonId;

        @Column(name = "lesson_topic_id", nullable = false)
        private UUID lessonTopicId;

        protected Id() {
        }

        Id(UUID lessonId, UUID lessonTopicId) {
            this.lessonId = lessonId;
            this.lessonTopicId = lessonTopicId;
        }

        @Override
        public boolean equals(Object other) {
            return other instanceof Id id
                    && Objects.equals(lessonId, id.lessonId)
                    && Objects.equals(lessonTopicId, id.lessonTopicId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(lessonId, lessonTopicId);
        }
    }
}
