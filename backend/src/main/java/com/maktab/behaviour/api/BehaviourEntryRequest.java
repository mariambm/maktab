package com.maktab.behaviour.api;

import com.maktab.behaviour.domain.Behaviour;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.Set;
import java.util.UUID;

/** What was observed about one student. Nothing selected and no note means nothing to record. */
public record BehaviourEntryRequest(
        @NotNull(message = "Student is required") UUID studentId,
        Set<@NotNull Behaviour> behaviours,
        @Size(max = 500, message = "Note is too long") String note) {

    public Set<Behaviour> behavioursOrEmpty() {
        return behaviours == null ? Set.of() : behaviours;
    }
}
