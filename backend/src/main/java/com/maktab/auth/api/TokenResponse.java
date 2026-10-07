package com.maktab.auth.api;

import java.time.Instant;

public record TokenResponse(
        String tokenType,
        String accessToken,
        Instant accessTokenExpiresAt,
        String refreshToken,
        Instant refreshTokenExpiresAt,
        MeResponse user) {

    @Override
    public String toString() {
        return "TokenResponse[user=" + user.id() + "]";
    }
}
