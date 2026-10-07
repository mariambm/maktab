package com.maktab.behaviour.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.util.List;

/** The behaviour observed in a lesson. A student who had observations and is left out no longer has any. */
public record RecordBehaviourRequest(
        @NotNull(message = "Observations are required") List<@Valid BehaviourEntryRequest> entries) {
}
