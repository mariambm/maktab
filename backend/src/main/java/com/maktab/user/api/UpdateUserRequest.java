package com.maktab.user.api;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateUserRequest(
        @NotBlank(message = "Email is required") @Email(message = "Enter a valid email address") @Size(max = 254)
        String email,
        @NotBlank(message = "First name is required") @Size(max = 100, message = "First name is too long")
        String firstName,
        @NotBlank(message = "Last name is required") @Size(max = 100, message = "Last name is too long")
        String lastName) {
}
