package com.maktab.user.api;

import jakarta.validation.constraints.NotNull;

public record UpdateStatusRequest(@NotNull(message = "Active is required") Boolean active) {
}
