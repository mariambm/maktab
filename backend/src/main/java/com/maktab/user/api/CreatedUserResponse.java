package com.maktab.user.api;

/**
 * Returned once when an account is created or its password is reset. The temporary password is shown to the
 * administrator a single time and is never stored in plain text or logged.
 */
public record CreatedUserResponse(UserResponse user, String temporaryPassword) {

    @Override
    public String toString() {
        return "CreatedUserResponse[user=" + user.id() + "]";
    }
}
