package com.maktab.progress.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.progress.application.TargetService;
import jakarta.validation.Valid;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TargetController {

    private final TargetService targets;

    public TargetController(TargetService targets) {
        this.targets = targets;
    }

    @GetMapping("/api/targets")
    @PreAuthorize("hasAuthority('STUDENT_READ')")
    public List<TargetResponse> forStudent(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam UUID studentId) {
        return targets.forStudent(currentUser, studentId);
    }

    @PostMapping("/api/targets")
    @PreAuthorize("hasAuthority('TARGET_MANAGE')")
    @ResponseStatus(HttpStatus.CREATED)
    public TargetResponse create(@AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody TargetRequest request) {
        return targets.create(currentUser, request);
    }

    @PutMapping("/api/targets/{id}")
    @PreAuthorize("hasAuthority('TARGET_MANAGE')")
    public TargetResponse update(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody TargetRequest request) {
        return targets.update(currentUser, id, request);
    }

    /** A class's students with their latest score and their targets for the period running now. */
    @GetMapping("/api/progress/classes/{classId}")
    @PreAuthorize("hasAuthority('CLASS_READ')")
    public ClassProgressResponse classOverview(@AuthenticationPrincipal CurrentUser currentUser,
            @PathVariable UUID classId) {
        return targets.classOverview(currentUser, classId);
    }
}
