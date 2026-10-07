package com.maktab.lesson.api;

import com.maktab.lesson.domain.LessonStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/** What the teacher records about the lesson itself: content, topics covered and whether it took place. */
public record UpdateLessonRequest(
        @Size(max = 2000, message = "Lesson notes are too long") String contentNotes,
        @NotNull(message = "Status is required") LessonStatus status,
        LocalTime endTime,
        Set<UUID> coveredTopicIds) {

    public Set<UUID> coveredTopicIdsOrEmpty() {
        return coveredTopicIds == null ? Set.of() : coveredTopicIds;
    }

    public List<UUID> asList() {
        return List.copyOf(coveredTopicIdsOrEmpty());
    }
}
