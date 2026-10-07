package com.maktab.curriculum.api;

import com.maktab.curriculum.domain.CurriculumPeriod;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record CurriculumPeriodResponse(
        UUID id,
        UUID curriculumLevelId,
        String curriculumLevelName,
        int number,
        String name,
        LocalDate startDate,
        LocalDate endDate,
        List<CurriculumWeekResponse> weeks) {

    public static CurriculumPeriodResponse of(CurriculumPeriod period, String levelName,
            List<CurriculumWeekResponse> weeks) {
        return new CurriculumPeriodResponse(period.getId(), period.getCurriculumLevelId(), levelName,
                period.getNumber(), period.getName(), period.getStartDate(), period.getEndDate(), weeks);
    }
}
