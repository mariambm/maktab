package com.maktab.user.api;

import com.maktab.user.domain.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.Set;

public record CreateUserRequest(
        @NotBlank(message = "Email is required") @Email(message = "Enter a valid email address") @Size(max = 254)
        String email,
        @NotBlank(message = "First name is required") @Size(max = 100, message = "First name is too long")
        String firstName,
        @NotBlank(message = "Last name is required") @Size(max = 100, message = "Last name is too long")
        String lastName,
        @NotEmpty(message = "Choose at least one role")
        Set<@NotNull Role> roles) {
}
