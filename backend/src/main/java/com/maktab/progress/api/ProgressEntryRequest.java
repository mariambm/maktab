package com.maktab.progress.api;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.util.UUID;

/** One student's score. The score must be a step of the organisation's progress scale. */
public record ProgressEntryRequest(
        @NotNull(message = "Student is required") UUID studentId,
        @NotNull(message = "Score is required") BigDecimal score,
        @Size(max = 500, message = "Note is too long") String note) {
}
