package com.maktab.behaviour.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.behaviour.application.BehaviourService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class BehaviourController {

    private final BehaviourService behaviour;

    public BehaviourController(BehaviourService behaviour) {
        this.behaviour = behaviour;
    }

    @GetMapping("/api/behaviour")
    @PreAuthorize("hasAuthority('STUDENT_READ')")
    public List<StudentBehaviourResponse> forStudent(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam UUID studentId) {
        return behaviour.forStudent(currentUser, studentId);
    }

    @GetMapping("/api/lessons/{id}/behaviour")
    @PreAuthorize("hasAuthority('CLASS_READ')")
    public LessonBehaviourResponse forLesson(@AuthenticationPrincipal CurrentUser currentUser,
            @PathVariable UUID id) {
        return behaviour.forLesson(currentUser, id);
    }

    @PutMapping("/api/lessons/{id}/behaviour")
    @PreAuthorize("hasAuthority('OBSERVATION_RECORD')")
    public LessonBehaviourResponse record(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody RecordBehaviourRequest request) {
        return behaviour.record(currentUser, id, request);
    }
}
