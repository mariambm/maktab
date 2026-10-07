package com.maktab.parent.api;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ParentRequest(
        @NotBlank(message = "First name is required") @Size(max = 100, message = "First name is too long")
        String firstName,
        @NotBlank(message = "Last name is required") @Size(max = 100, message = "Last name is too long")
        String lastName,
        @NotBlank(message = "Phone number is required")
        @Pattern(regexp = "^\\+?[0-9 ()-]{6,30}$", message = "Enter a valid phone number")
        String phone,
        @Email(message = "Enter a valid email address") @Size(max = 254, message = "Email is too long")
        String email) {
}
