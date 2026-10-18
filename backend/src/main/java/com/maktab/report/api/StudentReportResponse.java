package com.maktab.report.api;

import com.maktab.curriculum.domain.Subject;
import com.maktab.lesson.domain.AbsenceReason;
import com.maktab.progress.api.TargetResponse;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * One student over a date range: attendance, progress per subject, the targets of the periods in the range, and
 * counts of behaviour and uniform observations. {@code payments} is only filled in for callers with payment access.
 */
public record StudentReportResponse(
        UUID studentId,
        String firstName,
        String lastName,
        String className,
        LocalDate from,
        LocalDate to,
        Attendance attendance,
        List<SubjectProgress> progress,
        List<TargetResponse> targets,
        List<BehaviourReportResponse.BehaviourCount> behaviour,
        Uniform uniform,
        Payments payments) {

    public record Attendance(long lessons, long present, long late, long absent, Integer attendancePercentage,
            int thresholdPercentage, boolean belowThreshold, Map<AbsenceReason, Long> absenceReasons) {
    }

    public record SubjectProgress(Subject subject, long scores, BigDecimal averageScore, BigDecimal latestScore,
            String latestLabel, LocalDate latestDate) {
    }

    public record Uniform(long inOrder, long partiallyInOrder, long notInOrder) {
    }

    public record Payments(String currency, long months, long monthsOwing, BigDecimal expectedTotal,
            BigDecimal paidTotal, BigDecimal outstandingTotal) {
    }
}
