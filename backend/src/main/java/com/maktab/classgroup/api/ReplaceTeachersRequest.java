package com.maktab.classgroup.api;

import jakarta.validation.constraints.NotNull;
import java.util.Set;
import java.util.UUID;

public record ReplaceTeachersRequest(@NotNull(message = "Teachers are required") Set<@NotNull UUID> teacherIds) {
}
