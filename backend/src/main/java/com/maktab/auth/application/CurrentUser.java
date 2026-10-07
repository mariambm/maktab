package com.maktab.auth.application;

import com.maktab.user.domain.Permission;
import com.maktab.user.domain.Role;
import com.maktab.user.domain.User;
import java.util.Set;
import java.util.UUID;

/**
 * The authenticated caller, resolved from the database on every request so that deactivation and permission
 * changes take effect immediately. Injected into controllers with {@code @AuthenticationPrincipal}.
 */
public record CurrentUser(UUID id, UUID organisationId, String email, Set<Role> roles, Set<Permission> permissions) {

    public static CurrentUser of(User user) {
        return new CurrentUser(user.getId(), user.getOrganisationId(), user.getEmail(), user.getRoles(),
                user.effectivePermissions());
    }

    public boolean has(Permission permission) {
        return permissions.contains(permission);
    }

    public boolean hasRole(Role role) {
        return roles.contains(role);
    }
}
