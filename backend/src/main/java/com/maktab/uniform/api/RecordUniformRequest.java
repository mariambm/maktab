package com.maktab.uniform.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.util.List;

/** Uniform seen in a lesson. Only students worth noting need an entry; one left out no longer has a record. */
public record RecordUniformRequest(
        @NotNull(message = "Uniform records are required") List<@Valid UniformEntryRequest> entries) {
}
