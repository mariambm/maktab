package com.maktab.curriculum.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LessonTopicRequest(
        @NotBlank(message = "Topic title is required") @Size(max = 200, message = "Title is too long") String title,
        @Size(max = 500, message = "Learning objective is too long") String learningObjective) {
}
