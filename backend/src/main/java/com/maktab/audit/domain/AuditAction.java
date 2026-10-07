package com.maktab.audit.domain;

/** Actions written to the audit log. Stored as text, so new values need no migration. */
public enum AuditAction {
    LOGIN_SUCCEEDED,
    LOGIN_FAILED,
    PASSWORD_CHANGED,
    PASSWORD_RESET,
    USER_CREATED,
    USER_UPDATED,
    USER_ACTIVATED,
    USER_DEACTIVATED,
    USER_ROLES_CHANGED,
    USER_PERMISSIONS_CHANGED
}
