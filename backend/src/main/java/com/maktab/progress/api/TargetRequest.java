package com.maktab.progress.api;

import com.maktab.curriculum.domain.Subject;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.UUID;

/**
 * A target to create or update. The student and period are required to create one and fixed afterwards, so an
 * update ignores them.
 */
public record TargetRequest(
        UUID studentId,
        UUID curriculumPeriodId,
        Subject subject,
        @NotBlank(message = "Describe the target") @Size(max = 300, message = "Target is too long") String description,
        @Min(value = 0, message = "Enter a percentage from 0 to 100")
        @Max(value = 100, message = "Enter a percentage from 0 to 100") Integer targetPercentage,
        @Min(value = 0, message = "Enter a percentage from 0 to 100")
        @Max(value = 100, message = "Enter a percentage from 0 to 100") Integer currentPercentage,
        BigDecimal progressScore,
        @Size(max = 1000, message = "Note is too long") String teacherNote) {
}
