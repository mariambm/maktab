package com.maktab.uniform.api;

import com.maktab.uniform.domain.UniformReason;
import com.maktab.uniform.domain.UniformStatus;
import java.time.LocalDate;
import java.util.UUID;

public record StudentUniformResponse(UUID lessonId, LocalDate lessonDate, UUID classGroupId, String className,
        UniformStatus status, UniformReason reason, String note) {
}
