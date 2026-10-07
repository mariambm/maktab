package com.maktab.curriculum.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;
import java.util.List;

/** Create or update a four-week period. The end date follows from the start date, so it is not sent. */
public record CurriculumPeriodRequest(
        @NotNull(message = "Curriculum level is required") java.util.UUID curriculumLevelId,
        @NotNull(message = "Period number is required") @Min(value = 1, message = "Period number must be 1 or higher")
        Integer number,
        @NotBlank(message = "Name is required") @Size(max = 100, message = "Name is too long") String name,
        @NotNull(message = "Start date is required") LocalDate startDate,
        @Size(max = 4, message = "A period has four weeks") List<@Valid CurriculumWeekRequest> weeks) {

    public List<CurriculumWeekRequest> weeksOrEmpty() {
        return weeks == null ? List.of() : weeks;
    }
}
