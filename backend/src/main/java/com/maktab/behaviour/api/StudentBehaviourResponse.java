package com.maktab.behaviour.api;

import com.maktab.behaviour.domain.Behaviour;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

/** One lesson's observations in a student's history. */
public record StudentBehaviourResponse(UUID lessonId, LocalDate lessonDate, UUID classGroupId, String className,
        List<Behaviour> behaviours, String note) {
}
