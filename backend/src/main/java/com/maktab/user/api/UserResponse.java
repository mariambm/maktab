package com.maktab.user.api;

import com.maktab.user.domain.Permission;
import com.maktab.user.domain.Role;
import com.maktab.user.domain.User;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

public record UserResponse(
        UUID id,
        String email,
        String firstName,
        String lastName,
        boolean active,
        List<Role> roles,
        List<Permission> grantedPermissions,
        List<Permission> effectivePermissions,
        boolean mustChangePassword,
        Instant lastLoginAt) {

    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getEmail(), user.getFirstName(), user.getLastName(),
                user.isActive(), user.getRoles().stream().sorted().toList(),
                user.getGrantedPermissions().stream().sorted().toList(),
                user.effectivePermissions().stream().sorted().toList(),
                user.isMustChangePassword(), user.getLastLoginAt());
    }
}
