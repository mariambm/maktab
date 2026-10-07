package com.maktab.progress.api;

import com.maktab.curriculum.api.CurriculumPeriodSummary;
import com.maktab.curriculum.domain.Subject;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** A class at a glance: each student's latest score and their targets for the period running now. */
public record ClassProgressResponse(UUID classId, String className, CurriculumPeriodSummary period,
        List<StudentRow> students) {

    public record StudentRow(UUID studentId, String firstName, String lastName, LatestScore latestScore,
            List<TargetResponse> targets) {
    }

    public record LatestScore(LocalDate lessonDate, Subject subject, BigDecimal score, String label) {
    }
}
