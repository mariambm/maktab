package com.maktab.uniform.api;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.maktab.uniform.domain.UniformReason;
import com.maktab.uniform.domain.UniformStatus;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public record UniformEntryRequest(
        @NotNull(message = "Student is required") UUID studentId,
        @NotNull(message = "Uniform status is required") UniformStatus status,
        UniformReason reason,
        @Size(max = 500, message = "Note is too long") String note) {

    @JsonIgnore
    @AssertTrue(message = "Uniform in order has no reason")
    public boolean isReasonConsistent() {
        return status != UniformStatus.IN_ORDER || reason == null;
    }
}
