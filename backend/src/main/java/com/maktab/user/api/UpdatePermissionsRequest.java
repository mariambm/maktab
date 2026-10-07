package com.maktab.user.api;

import com.maktab.user.domain.Permission;
import jakarta.validation.constraints.NotNull;
import java.util.Set;

/** Extra permissions for one user on top of their roles. An empty set removes all extra grants. */
public record UpdatePermissionsRequest(@NotNull(message = "Permissions are required") Set<@NotNull Permission> permissions) {
}
