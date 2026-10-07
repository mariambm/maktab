package com.maktab.student.api;

import com.maktab.classgroup.api.ClassRef;
import com.maktab.student.domain.Gender;
import com.maktab.student.domain.StudentStatus;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public record StudentResponse(
        UUID id,
        String firstName,
        String lastName,
        LocalDate dateOfBirth,
        Gender gender,
        StudentStatus status,
        LocalDate joinedOn,
        LocalDate leftOn,
        String notes,
        ClassRef currentClass,
        List<StudentParentResponse> parents) {
}
