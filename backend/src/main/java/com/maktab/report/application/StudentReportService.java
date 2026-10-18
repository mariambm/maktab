package com.maktab.report.application;

import com.maktab.auth.application.CurrentUser;
import com.maktab.behaviour.domain.Behaviour;
import com.maktab.common.NotFoundException;
import com.maktab.curriculum.domain.Subject;
import com.maktab.lesson.domain.AbsenceReason;
import com.maktab.lesson.domain.AttendanceStatus;
import com.maktab.lesson.persistence.LessonAttendanceRepository;
import com.maktab.organisation.application.OrganisationCalendar;
import com.maktab.progress.api.TargetResponse;
import com.maktab.progress.application.ProgressScale;
import com.maktab.progress.application.TargetService;
import com.maktab.report.api.BehaviourReportResponse;
import com.maktab.report.api.StudentReportResponse;
import com.maktab.report.persistence.ReportQueries;
import com.maktab.student.application.StudentAccess;
import com.maktab.student.domain.Student;
import com.maktab.student.persistence.StudentRepository;
import com.maktab.uniform.domain.UniformStatus;
import com.maktab.user.domain.Permission;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * One student's report over a date range, for anyone who may see the student. Fees are added only for callers with
 * payment access, so a teacher's copy of the report never shows them.
 */
@Service
public class StudentReportService {

    private final ReportService reports;
    private final ReportQueries queries;
    private final StudentAccess studentAccess;
    private final StudentRepository students;
    private final LessonAttendanceRepository attendance;
    private final TargetService targets;
    private final ProgressScale scale;
    private final OrganisationCalendar calendar;

    public StudentReportService(ReportService reports, ReportQueries queries, StudentAccess studentAccess,
            StudentRepository students, LessonAttendanceRepository attendance, TargetService targets,
            ProgressScale scale, OrganisationCalendar calendar) {
        this.reports = reports;
        this.queries = queries;
        this.studentAccess = studentAccess;
        this.students = students;
        this.attendance = attendance;
        this.targets = targets;
        this.scale = scale;
        this.calendar = calendar;
    }

    @Transactional(readOnly = true)
    public StudentReportResponse report(CurrentUser actor, UUID studentId, LocalDate from, LocalDate to) {
        studentAccess.requireInScope(actor, studentId);
        Student student = students.findById(studentId).orElseThrow(() -> new NotFoundException("Student"));
        ReportRange range = ReportRange.of(from, to, calendar.today(actor.organisationId()));
        UUID classId = reports.currentClasses(Set.of(studentId)).get(studentId);
        String className = classId == null ? null : reports.classNames(Set.of(classId)).get(classId);

        return new StudentReportResponse(student.getId(), student.getFirstName(), student.getLastName(), className,
                range.from(), range.to(), attendance(actor, studentId, range), progress(actor, studentId, range),
                targets(actor, studentId, range), behaviour(studentId, range), uniform(studentId, range),
                actor.has(Permission.PAYMENT_READ) ? payments(actor, studentId, range) : null);
    }

    private StudentReportResponse.Attendance attendance(CurrentUser actor, UUID studentId, ReportRange range) {
        Figures.Tally tally = new Figures.Tally();
        Map<AbsenceReason, Long> reasons = new EnumMap<>(AbsenceReason.class);
        for (LessonAttendanceRepository.StudentAttendanceRow row :
                attendance.findForStudent(studentId, range.from(), range.to())) {
            tally.add(row.getStatus(), 1);
            if (row.getStatus() == AttendanceStatus.ABSENT && row.getAbsenceReason() != null) {
                reasons.merge(row.getAbsenceReason(), 1L, Long::sum);
            }
        }
        int threshold = reports.threshold(actor);
        Integer percentage = tally.percentage();
        return new StudentReportResponse.Attendance(tally.present + tally.late + tally.absent, tally.present,
                tally.late, tally.absent, percentage, threshold, percentage != null && percentage < threshold,
                reasons);
    }

    private List<StudentReportResponse.SubjectProgress> progress(CurrentUser actor, UUID studentId,
            ReportRange range) {
        ProgressScale.Lookup levels = scale.lookup(actor.organisationId());
        Map<Subject, ReportQueries.LatestScore> latest = new HashMap<>();
        for (ReportQueries.LatestScore score : queries.studentScoreHistory(studentId, range.from(), range.to())) {
            latest.putIfAbsent(score.subject(), score);
        }
        return queries.studentScores(studentId, range.from(), range.to()).stream()
                .sorted(Comparator.comparing(ReportQueries.ScoreSummary::subject))
                .map(summary -> {
                    ReportQueries.LatestScore last = latest.get(summary.subject());
                    BigDecimal lastScore = last == null ? null : last.score();
                    return new StudentReportResponse.SubjectProgress(summary.subject(), summary.scores(),
                            Figures.averageScore(summary.average()), lastScore, levels.labelOf(lastScore),
                            last == null ? null : last.lessonDate());
                })
                .toList();
    }

    /** The targets of every period that overlaps the range, latest period first. */
    private List<TargetResponse> targets(CurrentUser actor, UUID studentId, ReportRange range) {
        return targets.forStudent(actor, studentId).stream()
                .filter(t -> !t.period().startDate().isAfter(range.to())
                        && !t.period().endDate().isBefore(range.from()))
                .toList();
    }

    private List<BehaviourReportResponse.BehaviourCount> behaviour(UUID studentId, ReportRange range) {
        Map<Behaviour, Long> counts = new EnumMap<>(Behaviour.class);
        queries.studentBehaviour(studentId, range.from(), range.to())
                .forEach(row -> counts.merge(row.behaviour(), row.total(), Long::sum));
        return counts.entrySet().stream()
                .map(e -> new BehaviourReportResponse.BehaviourCount(e.getKey(), e.getKey().isGood(), e.getValue()))
                .sorted(Comparator.comparing(BehaviourReportResponse.BehaviourCount::count).reversed()
                        .thenComparing(BehaviourReportResponse.BehaviourCount::behaviour))
                .toList();
    }

    private StudentReportResponse.Uniform uniform(UUID studentId, ReportRange range) {
        Map<UniformStatus, Long> counts = queries.studentUniform(studentId, range.from(), range.to()).stream()
                .collect(Collectors.toMap(ReportQueries.UniformCount::status, ReportQueries.UniformCount::total));
        return new StudentReportResponse.Uniform(counts.getOrDefault(UniformStatus.IN_ORDER, 0L),
                counts.getOrDefault(UniformStatus.PARTIALLY_IN_ORDER, 0L),
                counts.getOrDefault(UniformStatus.NOT_IN_ORDER, 0L));
    }

    /** The fees of every month that falls (partly) in the range. */
    private StudentReportResponse.Payments payments(CurrentUser actor, UUID studentId, ReportRange range) {
        ReportQueries.StudentPaymentTotals totals = queries.studentPayments(studentId,
                range.from().withDayOfMonth(1), range.to().withDayOfMonth(1));
        BigDecimal expected = ReportService.money(totals.expected());
        BigDecimal paid = ReportService.money(totals.paid());
        return new StudentReportResponse.Payments(reports.currency(actor), orZero(totals.months()),
                orZero(totals.monthsOwing()), expected, paid, ReportService.money(expected.subtract(paid)));
    }

    private static long orZero(Long value) {
        return value == null ? 0 : value;
    }
}
