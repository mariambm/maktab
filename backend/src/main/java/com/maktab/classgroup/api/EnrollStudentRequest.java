package com.maktab.classgroup.api;

import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;
import java.util.UUID;

/** Puts a student in a class, ending their current class on the same date. {@code startDate} defaults to today. */
public record EnrollStudentRequest(
        @NotNull(message = "Choose a class") UUID classId,
        LocalDate startDate) {
}
