package com.maktab.progress.api;

import com.maktab.curriculum.api.CurriculumPeriodSummary;
import com.maktab.curriculum.domain.Subject;
import java.math.BigDecimal;
import java.util.UUID;

public record TargetResponse(UUID id, UUID studentId, CurriculumPeriodSummary period, Subject subject,
        String description, Integer targetPercentage, Integer currentPercentage, BigDecimal progressScore,
        String progressLabel, String teacherNote) {
}
