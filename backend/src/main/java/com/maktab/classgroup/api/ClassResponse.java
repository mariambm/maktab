package com.maktab.classgroup.api;

import java.util.List;
import java.util.UUID;

public record ClassResponse(
        UUID id,
        String name,
        CurriculumLevelResponse curriculumLevel,
        String room,
        boolean active,
        long studentCount,
        List<TeacherRef> teachers,
        List<ScheduleSlot> schedule) {
}
