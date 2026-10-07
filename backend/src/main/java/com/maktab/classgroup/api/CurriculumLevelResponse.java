package com.maktab.classgroup.api;

import com.maktab.classgroup.domain.CurriculumLevel;
import java.util.UUID;

public record CurriculumLevelResponse(UUID id, String name, int sortOrder) {

    public static CurriculumLevelResponse from(CurriculumLevel level) {
        return new CurriculumLevelResponse(level.getId(), level.getName(), level.getSortOrder());
    }
}
