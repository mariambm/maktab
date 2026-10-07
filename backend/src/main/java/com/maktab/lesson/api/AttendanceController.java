package com.maktab.lesson.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.lesson.application.AttendanceService;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/attendance")
public class AttendanceController {

    private final AttendanceService attendance;

    public AttendanceController(AttendanceService attendance) {
        this.attendance = attendance;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('STUDENT_READ')")
    public List<StudentAttendanceResponse> forStudent(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam UUID studentId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return attendance.forStudent(currentUser, studentId, from, to);
    }

    @GetMapping("/statistics")
    @PreAuthorize("hasAuthority('STUDENT_READ')")
    public AttendanceStatisticsResponse statistics(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam UUID studentId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return attendance.statisticsForStudent(currentUser, studentId, from, to);
    }
}
