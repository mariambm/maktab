package com.maktab.student.api;

import com.maktab.student.domain.ParentRelationship;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record ParentLinkRequest(
        @NotNull(message = "Choose a parent or guardian") UUID parentId,
        @NotNull(message = "Relationship is required") ParentRelationship relationship,
        Boolean primaryContact) {

    /** Omitted means false. */
    public boolean isPrimary() {
        return Boolean.TRUE.equals(primaryContact);
    }
}
