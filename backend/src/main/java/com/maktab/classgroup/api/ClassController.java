package com.maktab.classgroup.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.application.ClassService;
import com.maktab.common.PageResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
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
@RequestMapping("/api/classes")
public class ClassController {

    private final ClassService classService;

    public ClassController(ClassService classService) {
        this.classService = classService;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('CLASS_READ')")
    public PageResponse<ClassResponse> list(
            @AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) UUID levelId,
            @RequestParam(required = false) Boolean active,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "25") @Min(1) @Max(100) int size) {
        PageRequest pageable = PageRequest.of(page, size, Sort.by("name", "id"));
        return classService.search(currentUser, search, levelId, active, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('CLASS_READ')")
    public ClassResponse get(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id) {
        return classService.get(currentUser, id);
    }

    @GetMapping("/{id}/students")
    @PreAuthorize("hasAuthority('CLASS_READ') and hasAuthority('STUDENT_READ')")
    public List<ClassStudentResponse> students(@AuthenticationPrincipal CurrentUser currentUser,
            @PathVariable UUID id) {
        return classService.currentStudents(currentUser, id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('CLASS_MANAGE')")
    public ClassResponse create(@AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody ClassRequest request) {
        return classService.create(currentUser, request);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('CLASS_MANAGE')")
    public ClassResponse update(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody ClassRequest request) {
        return classService.update(currentUser, id, request);
    }

    @PutMapping("/{id}/teachers")
    @PreAuthorize("hasAuthority('CLASS_MANAGE')")
    public ClassResponse replaceTeachers(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody ReplaceTeachersRequest request) {
        return classService.replaceTeachers(currentUser, id, request.teacherIds());
    }

    @PutMapping("/{id}/schedule")
    @PreAuthorize("hasAuthority('CLASS_MANAGE')")
    public ClassResponse replaceSchedule(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody ReplaceScheduleRequest request) {
        return classService.replaceSchedule(currentUser, id, request.slots());
    }
}
