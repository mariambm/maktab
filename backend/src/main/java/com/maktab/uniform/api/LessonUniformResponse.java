package com.maktab.uniform.api;

import com.maktab.uniform.domain.UniformReason;
import com.maktab.uniform.domain.UniformStatus;
import java.util.List;
import java.util.UUID;

public record LessonUniformResponse(UUID lessonId, List<Entry> records) {

    public record Entry(UUID studentId, UniformStatus status, UniformReason reason, String note) {
    }
}
