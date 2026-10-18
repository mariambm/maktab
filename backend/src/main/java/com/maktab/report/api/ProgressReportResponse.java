package com.maktab.report.api;

import com.maktab.curriculum.api.CurriculumPeriodSummary;
import com.maktab.curriculum.domain.Subject;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

/**
 * Progress per class in the period running now, the students behind their target, and, for one class, how its
 * average score went over its recent periods. An average is null when no scores were given.
 */
public record ProgressReportResponse(List<ClassRow> classes, List<BehindTarget> behindTarget,
        List<PeriodRow> periods) {

    public record ClassRow(UUID classId, String className, CurriculumPeriodSummary period, int students,
            long scores, BigDecimal averageScore, int targets, int targetsBehind) {
    }

    /** A target whose current percentage is below the target percentage. */
    public record BehindTarget(UUID studentId, String firstName, String lastName, UUID classId, String className,
            UUID targetId, Subject subject, String description, Integer targetPercentage,
            Integer currentPercentage) {
    }

    public record PeriodRow(CurriculumPeriodSummary period, long scores, BigDecimal averageScore) {
    }
}
