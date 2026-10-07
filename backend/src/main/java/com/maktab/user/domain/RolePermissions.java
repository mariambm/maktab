package com.maktab.user.domain;

import static com.maktab.user.domain.Permission.*;

import java.util.Collection;
import java.util.EnumSet;
import java.util.Map;
import java.util.Set;

/**
 * The permissions each role carries. Extra permissions can be granted to an individual user (for example
 * PAYMENT_READ for one teacher) and are stored in {@code user_permission}.
 */
public final class RolePermissions {

    private static final Map<Role, Set<Permission>> BY_ROLE = Map.of(
            Role.ADMIN, EnumSet.allOf(Permission.class),
            Role.ADMINISTRATOR, EnumSet.of(
                    STUDENT_READ, STUDENT_WRITE, PARENT_READ, PARENT_WRITE, CLASS_READ, CLASS_MANAGE,
                    CURRICULUM_READ, CURRICULUM_WRITE, LESSON_RECORD, PROGRESS_RECORD, TARGET_MANAGE,
                    OBSERVATION_RECORD, PAYMENT_READ, PAYMENT_WRITE, REPORT_READ),
            Role.TEACHER, EnumSet.of(
                    STUDENT_READ, CLASS_READ, CURRICULUM_READ, LESSON_RECORD, PROGRESS_RECORD, TARGET_MANAGE,
                    OBSERVATION_RECORD, REPORT_READ));

    private RolePermissions() {
    }

    public static Set<Permission> forRole(Role role) {
        return EnumSet.copyOf(BY_ROLE.get(role));
    }

    /** Effective permissions: the union of every role's permissions plus the user's individual grants. */
    public static Set<Permission> effective(Collection<Role> roles, Collection<Permission> grants) {
        Set<Permission> result = EnumSet.noneOf(Permission.class);
        roles.forEach(role -> result.addAll(BY_ROLE.get(role)));
        result.addAll(grants);
        return result;
    }
}
