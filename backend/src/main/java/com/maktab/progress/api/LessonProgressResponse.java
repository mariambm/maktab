package com.maktab.progress.api;

import com.maktab.curriculum.domain.Subject;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/** Every score given in a lesson, for all subjects. */
public record LessonProgressResponse(UUID lessonId, List<Score> scores) {

    public record Score(UUID studentId, Subject subject, BigDecimal score, String note) {
    }
}
