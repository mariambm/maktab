package com.maktab.parent.api;

import com.maktab.student.domain.ParentRelationship;
import com.maktab.student.domain.StudentStatus;
import java.util.UUID;

public record ParentChildResponse(
        UUID studentId,
        String firstName,
        String lastName,
        StudentStatus status,
        ParentRelationship relationship,
        boolean primaryContact) {
}
