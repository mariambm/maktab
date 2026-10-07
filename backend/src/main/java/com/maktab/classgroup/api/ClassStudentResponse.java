package com.maktab.classgroup.api;

import java.time.LocalDate;
import java.util.UUID;

/** A student currently in a class. */
public record ClassStudentResponse(UUID id, String firstName, String lastName, LocalDate dateOfBirth,
        LocalDate enrolledSince) {
}
