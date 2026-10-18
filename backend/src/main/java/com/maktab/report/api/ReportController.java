package com.maktab.report.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.report.application.ReportService;
import com.maktab.report.application.StudentReportService;
import java.time.LocalDate;
import java.util.UUID;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Read-only reports. Each one counts over the classes the caller may see; without {@code from} and {@code to} a
 * report covers the last four weeks. The payment report also needs payment access.
 */
@RestController
public class ReportController {

    private final ReportService reports;
    private final StudentReportService studentReports;

    public ReportController(ReportService reports, StudentReportService studentReports) {
        this.reports = reports;
        this.studentReports = studentReports;
    }

    @GetMapping("/api/reports/dashboard")
    @PreAuthorize("hasAuthority('REPORT_READ')")
    public DashboardResponse dashboard(@AuthenticationPrincipal CurrentUser currentUser) {
        return reports.dashboard(currentUser);
    }

    @GetMapping("/api/reports/attendance")
    @PreAuthorize("hasAuthority('REPORT_READ')")
    public AttendanceReportResponse attendance(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID classId) {
        return reports.attendance(currentUser, from, to, classId);
    }

    @GetMapping("/api/reports/progress")
    @PreAuthorize("hasAuthority('REPORT_READ')")
    public ProgressReportResponse progress(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) UUID classId) {
        return reports.progress(currentUser, classId);
    }

    @GetMapping("/api/reports/behaviour")
    @PreAuthorize("hasAuthority('REPORT_READ')")
    public BehaviourReportResponse behaviour(@AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) UUID classId) {
        return reports.behaviour(currentUser, from, to, classId);
    }

    @GetMapping("/api/reports/payments")
    @PreAuthorize("hasAuthority('REPORT_READ') and hasAuthority('PAYMENT_READ')")
    public PaymentReportResponse payments(@AuthenticationPrincipal CurrentUser currentUser) {
        return reports.payments(currentUser);
    }

    @GetMapping("/api/reports/students/{id}")
    @PreAuthorize("hasAuthority('REPORT_READ')")
    public StudentReportResponse student(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return studentReports.report(currentUser, id, from, to);
    }
}
