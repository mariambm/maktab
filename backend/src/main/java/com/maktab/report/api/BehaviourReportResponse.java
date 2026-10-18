package com.maktab.report.api;

import com.maktab.behaviour.domain.Behaviour;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/**
 * Behaviour observations over a date range: how often each behaviour was seen, and the students for whom a
 * behaviour that needs attention came back several times. Observations stay tied to lessons; this only counts them.
 */
public record BehaviourReportResponse(LocalDate from, LocalDate to, long observations,
        List<BehaviourCount> behaviours, int recurringAtLeast, List<Recurring> recurring) {

    public record BehaviourCount(Behaviour behaviour, boolean good, long count) {
    }

    public record Recurring(UUID studentId, String firstName, String lastName, String className,
            Behaviour behaviour, long count, LocalDate lastSeen) {
    }
}
