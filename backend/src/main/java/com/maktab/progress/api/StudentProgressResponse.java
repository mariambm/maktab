package com.maktab.progress.api;

import com.maktab.curriculum.domain.Subject;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/** One score in a student's history, with the lesson it belongs to. */
public record StudentProgressResponse(UUID lessonId, LocalDate lessonDate, UUID classGroupId, String className,
        Subject subject, BigDecimal score, String label, String note) {
}
