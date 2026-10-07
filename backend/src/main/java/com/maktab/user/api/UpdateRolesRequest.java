package com.maktab.user.api;

import com.maktab.user.domain.Role;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.util.Set;

public record UpdateRolesRequest(@NotEmpty(message = "Choose at least one role") Set<@NotNull Role> roles) {
}
