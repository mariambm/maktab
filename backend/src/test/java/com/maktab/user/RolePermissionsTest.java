package com.maktab.user;

import static com.maktab.user.domain.Permission.*;
import static org.assertj.core.api.Assertions.assertThat;

import com.maktab.user.domain.Permission;
import com.maktab.user.domain.Role;
import com.maktab.user.domain.RolePermissions;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

class RolePermissionsTest {

    @Test
    void adminHasEveryPermission() {
        assertThat(RolePermissions.forRole(Role.ADMIN)).isEqualTo(EnumSet.allOf(Permission.class));
    }

    @Test
    void teacherCannotSeePaymentsOrManageAnything() {
        assertThat(RolePermissions.forRole(Role.TEACHER))
                .doesNotContain(PAYMENT_READ, PAYMENT_WRITE, USER_MANAGE, SETTINGS_MANAGE, AUDIT_READ,
                        STUDENT_WRITE, PARENT_READ, PARENT_WRITE, CLASS_MANAGE, CURRICULUM_WRITE)
                .contains(STUDENT_READ, LESSON_RECORD, PROGRESS_RECORD, OBSERVATION_RECORD, CURRICULUM_READ);
    }

    @Test
    void administratorRunsOperationsButCannotManageUsers() {
        assertThat(RolePermissions.forRole(Role.ADMINISTRATOR))
                .contains(STUDENT_WRITE, PARENT_WRITE, CLASS_MANAGE, PAYMENT_READ, PAYMENT_WRITE, REPORT_READ)
                .doesNotContain(USER_MANAGE, SETTINGS_MANAGE, AUDIT_READ);
    }

    @Test
    void individualGrantsAddToRolePermissions() {
        Set<Permission> effective = RolePermissions.effective(List.of(Role.TEACHER), List.of(PAYMENT_READ));
        assertThat(effective).contains(PAYMENT_READ, LESSON_RECORD).doesNotContain(PAYMENT_WRITE);
    }

    @Test
    void forRoleReturnsACopy() {
        RolePermissions.forRole(Role.TEACHER).add(PAYMENT_READ);
        assertThat(RolePermissions.forRole(Role.TEACHER)).doesNotContain(PAYMENT_READ);
    }
}
