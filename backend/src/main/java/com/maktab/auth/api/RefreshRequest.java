package com.maktab.auth.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RefreshRequest(@NotBlank(message = "Refresh token is required") @Size(max = 200) String refreshToken) {

    @Override
    public String toString() {
        return "RefreshRequest[***]";
    }
}
