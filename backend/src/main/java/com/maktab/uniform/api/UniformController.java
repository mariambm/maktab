package com.maktab.uniform.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.uniform.application.UniformService;
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
public class UniformController {

    private final UniformService uniform;

    public UniformController(UniformService uniform) {
        this.uniform = uniform;
    }

    @GetMapping("/api/uniform")
    @PreAuthorize("hasAuthority('STUDENT_READ')")
    public List<StudentUniformResponse> forStudent(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam UUID studentId) {
        return uniform.forStudent(currentUser, studentId);
    }

    @GetMapping("/api/lessons/{id}/uniform")
    @PreAuthorize("hasAuthority('CLASS_READ')")
    public LessonUniformResponse forLesson(@AuthenticationPrincipal CurrentUser currentUser,
            @PathVariable UUID id) {
        return uniform.forLesson(currentUser, id);
    }

    @PutMapping("/api/lessons/{id}/uniform")
    @PreAuthorize("hasAuthority('OBSERVATION_RECORD')")
    public LessonUniformResponse record(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody RecordUniformRequest request) {
        return uniform.record(currentUser, id, request);
    }
}
