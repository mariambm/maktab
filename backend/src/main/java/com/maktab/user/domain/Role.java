package com.maktab.user.domain;

public enum Role {
    /** Full system access, including users, roles, settings and the audit log. */
    ADMIN,
    /** Day-to-day administration: students, parents, classes, payments, reports. No user management. */
    ADMINISTRATOR,
    /** Access to assigned classes and their students only. */
    TEACHER
}
