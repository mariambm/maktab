package com.maktab.auth.api;

import com.maktab.user.domain.Permission;
import com.maktab.user.domain.Role;
import com.maktab.user.domain.User;
import java.util.List;
import java.util.UUID;

public record MeResponse(
        UUID id,
        String email,
        String firstName,
        String lastName,
        List<Role> roles,
        List<Permission> permissions,
        boolean mustChangePassword) {

    public static MeResponse from(User user) {
        return new MeResponse(user.getId(), user.getEmail(), user.getFirstName(), user.getLastName(),
                user.getRoles().stream().sorted().toList(),
                user.effectivePermissions().stream().sorted().toList(),
                user.isMustChangePassword());
    }
}
