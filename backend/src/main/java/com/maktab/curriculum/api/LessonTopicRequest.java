package com.maktab.curriculum.api;

import com.maktab.curriculum.domain.Subject;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record LessonTopicRequest(
        @NotNull(message = "Choose a subject") Subject subject,
        @NotBlank(message = "Topic title is required") @Size(max = 200, message = "Title is too long") String title,
        @Size(max = 500, message = "Learning objective is too long") String learningObjective) {
}
