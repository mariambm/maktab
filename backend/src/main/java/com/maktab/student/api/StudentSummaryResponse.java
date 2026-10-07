package com.maktab.student.api;

import com.maktab.classgroup.api.ClassRef;
import com.maktab.student.domain.StudentStatus;
import java.time.LocalDate;
import java.util.UUID;

/** A row in the students list. {@code currentClass} is null when the student is not in a class. */
public record StudentSummaryResponse(
        UUID id,
        String firstName,
        String lastName,
        LocalDate dateOfBirth,
        StudentStatus status,
        ClassRef currentClass) {
}
