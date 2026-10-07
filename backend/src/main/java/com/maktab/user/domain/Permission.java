package com.maktab.user.domain;

/**
 * Fine-grained rights checked on every endpoint. Whether a permission covers all classes or only the caller's
 * assigned classes is decided by the data scope ({@link com.maktab.common.AccessScope}), not by the permission
 * itself.
 */
public enum Permission {
    USER_MANAGE,
    SETTINGS_MANAGE,
    AUDIT_READ,
    STUDENT_READ,
    STUDENT_WRITE,
    PARENT_READ,
    PARENT_WRITE,
    CLASS_READ,
    CLASS_MANAGE,
    CURRICULUM_READ,
    CURRICULUM_WRITE,
    LESSON_RECORD,
    PROGRESS_RECORD,
    TARGET_MANAGE,
    OBSERVATION_RECORD,
    PAYMENT_READ,
    PAYMENT_WRITE,
    REPORT_READ
}
