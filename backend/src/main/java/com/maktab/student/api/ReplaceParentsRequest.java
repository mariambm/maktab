package com.maktab.student.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record ReplaceParentsRequest(
        @NotNull(message = "Parents are required")
        @Size(max = 4, message = "A student can have at most 4 parents or guardians")
        List<@NotNull @Valid ParentLinkRequest> parents) {
}
