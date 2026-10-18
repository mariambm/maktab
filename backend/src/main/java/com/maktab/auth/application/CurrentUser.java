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

    /**
     * The caller as the server treats them. While an account still has a temporary password it gets no roles or
     * permissions, so it can only read itself and change its password (endpoints that only need a signed-in user);
     * the app shows the change-password screen, and the server enforces the same.
     */
    public static CurrentUser of(User user) {
        if (user.isMustChangePassword()) {
            return new CurrentUser(user.getId(), user.getOrganisationId(), user.getEmail(), Set.of(), Set.of());
        }
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
