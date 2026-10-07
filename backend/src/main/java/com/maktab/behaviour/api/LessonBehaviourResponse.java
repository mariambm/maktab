package com.maktab.behaviour.api;

import com.maktab.behaviour.domain.Behaviour;
import java.util.List;
import java.util.UUID;

public record LessonBehaviourResponse(UUID lessonId, List<Observation> observations) {

    public record Observation(UUID studentId, List<Behaviour> behaviours, String note) {
    }
}
