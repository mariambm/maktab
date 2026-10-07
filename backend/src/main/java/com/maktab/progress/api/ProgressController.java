package com.maktab.progress.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.progress.application.ProgressService;
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
public class ProgressController {

    private final ProgressService progress;

    public ProgressController(ProgressService progress) {
        this.progress = progress;
    }

    /** The scores a teacher can give, with their labels, lowest first. */
    @GetMapping("/api/progress/scale")
    @PreAuthorize("isAuthenticated()")
    public List<ProgressScaleLevelResponse> scale(@AuthenticationPrincipal CurrentUser currentUser) {
        return progress.scale(currentUser);
    }

    @GetMapping("/api/progress")
    @PreAuthorize("hasAuthority('STUDENT_READ')")
    public List<StudentProgressResponse> forStudent(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam UUID studentId) {
        return progress.forStudent(currentUser, studentId);
    }

    @GetMapping("/api/lessons/{id}/progress")
    @PreAuthorize("hasAuthority('CLASS_READ')")
    public LessonProgressResponse forLesson(@AuthenticationPrincipal CurrentUser currentUser,
            @PathVariable UUID id) {
        return progress.forLesson(currentUser, id);
    }

    @PutMapping("/api/lessons/{id}/progress")
    @PreAuthorize("hasAuthority('PROGRESS_RECORD')")
    public LessonProgressResponse record(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody RecordProgressRequest request) {
        return progress.record(currentUser, id, request);
    }
}
