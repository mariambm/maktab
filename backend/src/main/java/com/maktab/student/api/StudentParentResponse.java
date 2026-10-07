package com.maktab.student.api;

import com.maktab.student.domain.ParentRelationship;
import java.util.UUID;

/** A parent/guardian as shown on a student's profile. {@code email} is null for callers without PARENT_READ. */
public record StudentParentResponse(
        UUID parentId,
        String firstName,
        String lastName,
        String phone,
        String email,
        ParentRelationship relationship,
        boolean primaryContact) {
}
