package com.maktab.progress.api;

import com.maktab.curriculum.domain.Subject;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.util.List;

/**
 * The scores for one subject in a lesson. The list is the whole picture for that subject: a student who had a score
 * and is left out no longer has one.
 */
public record RecordProgressRequest(
        @NotNull(message = "Subject is required") Subject subject,
        @NotNull(message = "Scores are required") List<@Valid ProgressEntryRequest> entries) {
}
