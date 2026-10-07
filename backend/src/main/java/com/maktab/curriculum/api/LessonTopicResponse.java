package com.maktab.curriculum.api;

import com.maktab.curriculum.domain.LessonTopic;
import java.util.UUID;

public record LessonTopicResponse(UUID id, String title, String learningObjective, int sortOrder) {

    public static LessonTopicResponse from(LessonTopic topic) {
        return new LessonTopicResponse(topic.getId(), topic.getTitle(), topic.getLearningObjective(),
                topic.getSortOrder());
    }
}
