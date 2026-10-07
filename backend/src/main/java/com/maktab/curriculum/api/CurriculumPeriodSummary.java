package com.maktab.curriculum.api;

import com.maktab.curriculum.domain.CurriculumPeriod;
import java.time.LocalDate;
import java.util.UUID;

/** A period without its weeks, for lists and for the lesson screen's header. */
public record CurriculumPeriodSummary(
        UUID id,
        UUID curriculumLevelId,
        int number,
        String name,
        LocalDate startDate,
        LocalDate endDate) {

    public static CurriculumPeriodSummary from(CurriculumPeriod period) {
        return new CurriculumPeriodSummary(period.getId(), period.getCurriculumLevelId(), period.getNumber(),
                period.getName(), period.getStartDate(), period.getEndDate());
    }
}
