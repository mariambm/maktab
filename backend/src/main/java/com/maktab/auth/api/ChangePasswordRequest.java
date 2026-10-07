package com.maktab.auth.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ChangePasswordRequest(
        @NotBlank(message = "Current password is required") @Size(max = 200)
        String currentPassword,
        @NotBlank(message = "New password is required")
        @Size(min = 10, max = 200, message = "New password must be at least 10 characters")
        String newPassword) {

    @Override
    public String toString() {
        return "ChangePasswordRequest[***]";
    }
}
