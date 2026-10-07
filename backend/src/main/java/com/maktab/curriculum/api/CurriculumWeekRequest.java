package com.maktab.curriculum.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record CurriculumWeekRequest(
        @NotNull(message = "Week number is required") @Min(1) @Max(4) Integer weekNumber,
        Boolean review,
        @Size(max = 20, message = "A week can hold at most 20 topics") List<@Valid LessonTopicRequest> topics) {

    public List<LessonTopicRequest> topicsOrEmpty() {
        return topics == null ? List.of() : topics;
    }

    public boolean isReview() {
        return Boolean.TRUE.equals(review);
    }
}
