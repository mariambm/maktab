package com.maktab.student.api;

import com.maktab.student.domain.StudentStatus;
import jakarta.validation.constraints.NotNull;

public record UpdateStudentStatusRequest(@NotNull(message = "Status is required") StudentStatus status) {
}
