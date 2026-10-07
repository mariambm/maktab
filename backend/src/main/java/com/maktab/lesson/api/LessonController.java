package com.maktab.lesson.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.common.PageResponse;
import com.maktab.lesson.application.LessonService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/lessons")
public class LessonController {

    private final LessonService lessons;

    public LessonController(LessonService lessons) {
        this.lessons = lessons;
    }

    /** The caller's lessons for a day (today by default): scheduled slots and lessons already opened. */
    @GetMapping("/today")
    @PreAuthorize("hasAuthority('CLASS_READ')")
    public List<LessonSummaryResponse> today(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return lessons.onDate(currentUser, date);
    }

    @GetMapping
    @PreAuthorize("hasAuthority('CLASS_READ')")
    public PageResponse<LessonSummaryResponse> list(
            @AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) UUID classId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "25") @Min(1) @Max(100) int size) {
        PageRequest pageable = PageRequest.of(page, size,
                Sort.by(Sort.Direction.DESC, "lessonDate").and(Sort.by("startTime")));
        return lessons.search(currentUser, classId, from, to, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('CLASS_READ')")
    public LessonDetailResponse get(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id) {
        return lessons.get(currentUser, id);
    }

    /** Opens a lesson; returns the existing one when it was already opened, so tapping twice is harmless. */
    @PostMapping
    @PreAuthorize("hasAuthority('LESSON_RECORD')")
    public LessonDetailResponse open(@AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody OpenLessonRequest request) {
        return lessons.open(currentUser, request);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('LESSON_RECORD')")
    public LessonDetailResponse update(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody UpdateLessonRequest request) {
        return lessons.update(currentUser, id, request);
    }

    @PutMapping("/{id}/attendance")
    @PreAuthorize("hasAuthority('LESSON_RECORD')")
    public LessonDetailResponse recordAttendance(@AuthenticationPrincipal CurrentUser currentUser,
            @PathVariable UUID id, @Valid @RequestBody RecordAttendanceRequest request) {
        return lessons.recordAttendance(currentUser, id, request.entries());
    }
}
