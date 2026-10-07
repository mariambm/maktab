package com.maktab.student.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.api.EnrollStudentRequest;
import com.maktab.classgroup.api.EnrollmentResponse;
import com.maktab.common.PageResponse;
import com.maktab.student.application.StudentService;
import com.maktab.student.domain.StudentStatus;
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
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/students")
public class StudentController {

    private final StudentService studentService;

    public StudentController(StudentService studentService) {
        this.studentService = studentService;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('STUDENT_READ')")
    public PageResponse<StudentSummaryResponse> list(
            @AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) UUID classId,
            @RequestParam(required = false) StudentStatus status,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "25") @Min(1) @Max(100) int size) {
        PageRequest pageable = PageRequest.of(page, size, Sort.by("lastName", "firstName", "id"));
        return studentService.search(currentUser, search, classId, status, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('STUDENT_READ')")
    public StudentResponse get(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id) {
        return studentService.get(currentUser, id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('STUDENT_WRITE')")
    public StudentResponse create(@AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody CreateStudentRequest request) {
        return studentService.create(currentUser, request);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('STUDENT_WRITE')")
    public StudentResponse update(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody UpdateStudentRequest request) {
        return studentService.update(currentUser, id, request);
    }

    @PatchMapping("/{id}/status")
    @PreAuthorize("hasAuthority('STUDENT_WRITE')")
    public StudentResponse updateStatus(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody UpdateStudentStatusRequest request) {
        return studentService.setStatus(currentUser, id, request.status());
    }

    @PutMapping("/{id}/parents")
    @PreAuthorize("hasAuthority('STUDENT_WRITE') and hasAuthority('PARENT_READ')")
    public StudentResponse replaceParents(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody ReplaceParentsRequest request) {
        return studentService.replaceParents(currentUser, id, request.parents());
    }

    @GetMapping("/{id}/enrollments")
    @PreAuthorize("hasAuthority('STUDENT_READ')")
    public List<EnrollmentResponse> enrollments(@AuthenticationPrincipal CurrentUser currentUser,
            @PathVariable UUID id) {
        return studentService.enrollmentHistory(currentUser, id);
    }

    @PostMapping("/{id}/enrollments")
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('STUDENT_WRITE')")
    public EnrollmentResponse enrol(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody EnrollStudentRequest request) {
        return studentService.enrol(currentUser, id, request.classId(), request.startDate());
    }

    @DeleteMapping("/{id}/enrollments/current")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    @PreAuthorize("hasAuthority('STUDENT_WRITE')")
    public void endEnrollment(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id) {
        studentService.endEnrollment(currentUser, id);
    }
}
