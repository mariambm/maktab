package com.maktab.curriculum.api;

import com.maktab.curriculum.domain.LessonTopic;
import com.maktab.curriculum.domain.Subject;
import java.util.UUID;

/** {@code subject} is null only for topics written before subjects existed. */
public record LessonTopicResponse(UUID id, Subject subject, String title, String learningObjective, int sortOrder) {

    public static LessonTopicResponse from(LessonTopic topic) {
        return new LessonTopicResponse(topic.getId(), topic.getSubject(), topic.getTitle(),
                topic.getLearningObjective(), topic.getSortOrder());
    }
}
