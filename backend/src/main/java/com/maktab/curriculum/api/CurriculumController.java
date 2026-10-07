package com.maktab.curriculum.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.curriculum.application.CurriculumService;
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
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/curriculum/periods")
public class CurriculumController {

    private final CurriculumService curriculum;

    public CurriculumController(CurriculumService curriculum) {
        this.curriculum = curriculum;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('CURRICULUM_READ')")
    public List<CurriculumPeriodSummary> list(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) UUID levelId) {
        return curriculum.list(currentUser, levelId);
    }

    /** The period that covers today for this level. */
    @GetMapping("/current")
    @PreAuthorize("hasAuthority('CURRICULUM_READ')")
    public CurriculumPeriodResponse current(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam UUID levelId) {
        return curriculum.current(currentUser, levelId);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('CURRICULUM_READ')")
    public CurriculumPeriodResponse get(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id) {
        return curriculum.get(currentUser, id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('CURRICULUM_WRITE')")
    public CurriculumPeriodResponse create(@AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody CurriculumPeriodRequest request) {
        return curriculum.create(currentUser, request);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('CURRICULUM_WRITE')")
    public CurriculumPeriodResponse update(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody CurriculumPeriodRequest request) {
        return curriculum.update(currentUser, id, request);
    }
}
