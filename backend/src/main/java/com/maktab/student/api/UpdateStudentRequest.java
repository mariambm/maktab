package com.maktab.student.api;

import com.maktab.student.domain.Gender;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Past;
import jakarta.validation.constraints.Size;
import java.time.LocalDate;

public record UpdateStudentRequest(
        @NotBlank(message = "First name is required") @Size(max = 100, message = "First name is too long")
        String firstName,
        @NotBlank(message = "Last name is required") @Size(max = 100, message = "Last name is too long")
        String lastName,
        @NotNull(message = "Date of birth is required") @Past(message = "Date of birth must be in the past")
        LocalDate dateOfBirth,
        Gender gender,
        @NotNull(message = "Join date is required")
        LocalDate joinedOn,
        @Size(max = 1000, message = "Notes are too long (1000 characters maximum)")
        String notes) {
}
