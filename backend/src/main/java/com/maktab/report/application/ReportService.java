package com.maktab.report.application;

import com.maktab.auth.application.CurrentUser;
import com.maktab.behaviour.domain.Behaviour;
import com.maktab.classgroup.application.AccessScopeService;
import com.maktab.classgroup.domain.ClassEnrollment;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.persistence.ClassEnrollmentRepository;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.common.AccessScope;
import com.maktab.common.NotFoundException;
import com.maktab.curriculum.api.CurriculumPeriodSummary;
import com.maktab.curriculum.application.CurriculumService;
import com.maktab.curriculum.domain.CurriculumPeriod;
import com.maktab.curriculum.persistence.CurriculumPeriodRepository;
import com.maktab.lesson.domain.AbsenceReason;
import com.maktab.organisation.application.OrganisationCalendar;
import com.maktab.organisation.domain.Organisation;
import com.maktab.organisation.persistence.OrganisationRepository;
import com.maktab.payment.api.PaymentPeriodResponse;
import com.maktab.payment.application.PaymentService;
import com.maktab.progress.domain.StudentTarget;
import com.maktab.progress.persistence.StudentTargetRepository;
import com.maktab.report.api.AttendanceReportResponse;
import com.maktab.report.api.BehaviourReportResponse;
import com.maktab.report.api.DashboardResponse;
import com.maktab.report.api.PaymentReportResponse;
import com.maktab.report.api.ProgressReportResponse;
import com.maktab.report.persistence.ReportQueries;
import com.maktab.student.domain.Student;
import com.maktab.student.persistence.StudentRepository;
import com.maktab.user.domain.Permission;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Comparator;
import java.util.EnumMap;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The reports and the dashboard figures. Nothing is stored: every figure is counted from the attendance, scores,
 * targets, observations and payments at the moment it is asked for, over the classes the caller may see.
 */
@Service
public class ReportService {

    /** A behaviour that needs attention is called recurring when a student shows it this often in the range. */
    static final int RECURRING_AT_LEAST = 3;
    /** How many months the payment report looks back over. */
    static final int PAYMENT_MONTHS = 12;
    /** How many earlier periods the progress report shows for one class. */
    static final int PERIOD_HISTORY = 6;

    private final ReportQueries queries;
    private final AccessScopeService scopes;
    private final ClassGroupRepository classes;
    private final ClassEnrollmentRepository enrollments;
    private final StudentRepository students;
    private final StudentTargetRepository targets;
    private final CurriculumService curriculum;
    private final CurriculumPeriodRepository periods;
    private final PaymentService payments;
    private final OrganisationRepository organisations;
    private final OrganisationCalendar calendar;

    public ReportService(ReportQueries queries, AccessScopeService scopes, ClassGroupRepository classes,
            ClassEnrollmentRepository enrollments, StudentRepository students, StudentTargetRepository targets,
            CurriculumService curriculum, CurriculumPeriodRepository periods, PaymentService payments,
            OrganisationRepository organisations, OrganisationCalendar calendar) {
        this.queries = queries;
        this.scopes = scopes;
        this.classes = classes;
        this.enrollments = enrollments;
        this.students = students;
        this.targets = targets;
        this.curriculum = curriculum;
        this.periods = periods;
        this.payments = payments;
        this.organisations = organisations;
        this.calendar = calendar;
    }

    @Transactional(readOnly = true)
    public AttendanceReportResponse attendance(CurrentUser actor, LocalDate from, LocalDate to, UUID classId) {
        ReportRange range = ReportRange.of(from, to, calendar.today(actor.organisationId()));
        return attendance(actor, range, classId);
    }

    private AttendanceReportResponse attendance(CurrentUser actor, ReportRange range, UUID classId) {
        ReportQueries.Filter filter = filter(actor, range, classId);
        List<ReportQueries.AttendanceCount> rows = queries.attendance(filter);
        Figures.Tally total = new Figures.Tally();
        Map<UUID, Figures.Tally> byClass = new HashMap<>();
        Map<UUID, Figures.Tally> byStudent = new HashMap<>();
        Map<AbsenceReason, Long> reasons = new EnumMap<>(AbsenceReason.class);
        for (ReportQueries.AttendanceCount row : rows) {
            total.add(row.status(), row.total());
            byClass.computeIfAbsent(row.classId(), id -> new Figures.Tally()).add(row.status(), row.total());
            byStudent.computeIfAbsent(row.studentId(), id -> new Figures.Tally()).add(row.status(), row.total());
            if (row.reason() != null) {
                reasons.merge(row.reason(), row.total(), Long::sum);
            }
        }
        for (ReportQueries.ClassLessons lessons : queries.registeredLessons(filter)) {
            byClass.computeIfAbsent(lessons.classId(), id -> new Figures.Tally()).lessons = lessons.lessons();
            total.lessons += lessons.lessons();
        }
        Map<UUID, String> classNames = classNames(byClass.keySet());
        List<AttendanceReportResponse.ClassRow> classRows = byClass.entrySet().stream()
                .map(e -> new AttendanceReportResponse.ClassRow(e.getKey(), classNames.get(e.getKey()),
                        e.getValue().counts()))
                .sorted(Comparator.comparing(AttendanceReportResponse.ClassRow::className,
                        String.CASE_INSENSITIVE_ORDER))
                .toList();

        int threshold = threshold(actor);
        Map<UUID, Figures.Tally> below = byStudent.entrySet().stream()
                .filter(e -> e.getValue().percentage() != null && e.getValue().percentage() < threshold)
                .collect(Collectors.toMap(Map.Entry::getKey, Map.Entry::getValue));
        Map<UUID, Student> studentById = studentsById(below.keySet());
        Map<UUID, UUID> currentClass = currentClasses(below.keySet());
        Map<UUID, String> currentClassNames = classNames(Set.copyOf(currentClass.values()));
        List<AttendanceReportResponse.StudentRow> studentRows = below.entrySet().stream()
                .filter(e -> studentById.containsKey(e.getKey()))
                .map(e -> {
                    Student student = studentById.get(e.getKey());
                    UUID studentClass = currentClass.get(e.getKey());
                    return new AttendanceReportResponse.StudentRow(student.getId(), student.getFirstName(),
                            student.getLastName(), studentClass, currentClassNames.get(studentClass),
                            e.getValue().counts());
                })
                .sorted(Comparator.comparing((AttendanceReportResponse.StudentRow r) ->
                                r.counts().attendancePercentage())
                        .thenComparing(AttendanceReportResponse.StudentRow::lastName, String.CASE_INSENSITIVE_ORDER)
                        .thenComparing(AttendanceReportResponse.StudentRow::firstName, String.CASE_INSENSITIVE_ORDER))
                .toList();
        return new AttendanceReportResponse(range.from(), range.to(), threshold, total.counts(), reasons, classRows,
                studentRows);
    }

    @Transactional(readOnly = true)
    public ProgressReportResponse progress(CurrentUser actor, UUID classId) {
        AccessScope scope = scopes.scopeFor(actor);
        LocalDate today = calendar.today(actor.organisationId());
        List<ClassGroup> reported = classId != null ? List.of(requireClass(actor, scope, classId))
                : classes.findByOrganisationIdAndActiveTrue(actor.organisationId()).stream()
                        .filter(c -> scope.includes(c.getId()))
                        .sorted(Comparator.comparing(ClassGroup::getName, String.CASE_INSENSITIVE_ORDER))
                        .toList();

        List<ProgressReportResponse.ClassRow> classRows = new ArrayList<>();
        List<ProgressReportResponse.BehindTarget> behind = new ArrayList<>();
        for (ClassGroup classGroup : reported) {
            Optional<CurriculumPeriod> period = curriculum.periodOn(classGroup.getCurriculumLevelId(), today);
            Set<UUID> roster = enrollments.findByClassGroupIdAndEndDateIsNull(classGroup.getId()).stream()
                    .map(ClassEnrollment::getStudentId).collect(Collectors.toSet());
            LocalDate start = period.map(CurriculumPeriod::getStartDate)
                    .orElse(today.minusDays(ReportRange.DEFAULT_DAYS - 1));
            LocalDate end = period.map(CurriculumPeriod::getEndDate).orElse(today);
            Average average = average(queries.classScores(classGroup.getId(), start, end));
            List<StudentTarget> periodTargets = period.isEmpty() || roster.isEmpty() ? List.of()
                    : targets.findByCurriculumPeriodIdAndStudentIdIn(period.get().getId(), roster);
            List<StudentTarget> behindTargets = periodTargets.stream().filter(ReportService::isBehind).toList();
            classRows.add(new ProgressReportResponse.ClassRow(classGroup.getId(), classGroup.getName(),
                    period.map(CurriculumPeriodSummary::from).orElse(null), roster.size(), average.scores(),
                    average.value(), periodTargets.size(), behindTargets.size()));
            Map<UUID, Student> studentById = studentsById(
                    behindTargets.stream().map(StudentTarget::getStudentId).collect(Collectors.toSet()));
            for (StudentTarget target : behindTargets) {
                Student student = studentById.get(target.getStudentId());
                if (student != null) {
                    behind.add(new ProgressReportResponse.BehindTarget(student.getId(), student.getFirstName(),
                            student.getLastName(), classGroup.getId(), classGroup.getName(), target.getId(),
                            target.getSubject(), target.getDescription(), toInteger(target.getTargetPercentage()),
                            toInteger(target.getCurrentPercentage())));
                }
            }
        }
        behind.sort(Comparator.comparing(ProgressReportResponse.BehindTarget::className, String.CASE_INSENSITIVE_ORDER)
                .thenComparing(ProgressReportResponse.BehindTarget::lastName, String.CASE_INSENSITIVE_ORDER)
                .thenComparing(ProgressReportResponse.BehindTarget::firstName, String.CASE_INSENSITIVE_ORDER));

        List<ProgressReportResponse.PeriodRow> history = List.of();
        if (classId != null) {
            ClassGroup classGroup = reported.getFirst();
            List<CurriculumPeriod> started = periods.findByCurriculumLevelIdOrderByNumberAsc(
                            classGroup.getCurriculumLevelId()).stream()
                    .filter(p -> !p.getStartDate().isAfter(today))
                    .sorted(Comparator.comparing(CurriculumPeriod::getStartDate))
                    .toList();
            history = started.subList(Math.max(0, started.size() - PERIOD_HISTORY), started.size()).stream()
                    .map(p -> {
                        Average average = average(queries.classScores(classGroup.getId(), p.getStartDate(),
                                p.getEndDate()));
                        return new ProgressReportResponse.PeriodRow(CurriculumPeriodSummary.from(p), average.scores(),
                                average.value());
                    })
                    .toList();
        }
        return new ProgressReportResponse(classRows, behind, history);
    }

    @Transactional(readOnly = true)
    public BehaviourReportResponse behaviour(CurrentUser actor, LocalDate from, LocalDate to, UUID classId) {
        ReportRange range = ReportRange.of(from, to, calendar.today(actor.organisationId()));
        ReportQueries.Filter filter = filter(actor, range, classId);
        List<ReportQueries.BehaviourCount> rows = queries.behaviour(filter);

        Map<Behaviour, Long> perBehaviour = new EnumMap<>(Behaviour.class);
        rows.forEach(row -> perBehaviour.merge(row.behaviour(), row.total(), Long::sum));
        List<BehaviourReportResponse.BehaviourCount> behaviours = perBehaviour.entrySet().stream()
                .map(e -> new BehaviourReportResponse.BehaviourCount(e.getKey(), e.getKey().isGood(), e.getValue()))
                .sorted(Comparator.comparing(BehaviourReportResponse.BehaviourCount::count).reversed()
                        .thenComparing(BehaviourReportResponse.BehaviourCount::behaviour))
                .toList();

        List<ReportQueries.BehaviourCount> recurringRows = rows.stream()
                .filter(row -> !row.behaviour().isGood() && row.total() >= RECURRING_AT_LEAST)
                .toList();
        Set<UUID> studentIds = recurringRows.stream().map(ReportQueries.BehaviourCount::studentId)
                .collect(Collectors.toSet());
        Map<UUID, Student> studentById = studentsById(studentIds);
        Map<UUID, UUID> currentClass = currentClasses(studentIds);
        Map<UUID, String> classNames = classNames(Set.copyOf(currentClass.values()));
        List<BehaviourReportResponse.Recurring> recurring = recurringRows.stream()
                .filter(row -> studentById.containsKey(row.studentId()))
                .map(row -> {
                    Student student = studentById.get(row.studentId());
                    return new BehaviourReportResponse.Recurring(student.getId(), student.getFirstName(),
                            student.getLastName(), classNames.get(currentClass.get(student.getId())),
                            row.behaviour(), row.total(), row.lastSeen());
                })
                .sorted(Comparator.comparing(BehaviourReportResponse.Recurring::count).reversed()
                        .thenComparing(BehaviourReportResponse.Recurring::lastName, String.CASE_INSENSITIVE_ORDER)
                        .thenComparing(BehaviourReportResponse.Recurring::firstName, String.CASE_INSENSITIVE_ORDER))
                .toList();
        return new BehaviourReportResponse(range.from(), range.to(), queries.behaviourRecords(filter), behaviours,
                RECURRING_AT_LEAST, recurring);
    }

    /** Callers reach this only with payment access; the totals are counted over the students they may see. */
    @Transactional(readOnly = true)
    public PaymentReportResponse payments(CurrentUser actor) {
        AccessScope scope = scopes.scopeFor(actor);
        List<PaymentPeriodResponse> months = pastMonths(actor).stream().limit(PAYMENT_MONTHS).toList();
        String currency = currency(actor);
        if (months.isEmpty()) {
            return new PaymentReportResponse(currency, months, PaymentPeriodResponse.Totals.NONE, List.of());
        }
        PaymentPeriodResponse.Totals totals = months.stream().map(PaymentPeriodResponse::totals)
                .reduce(PaymentPeriodResponse.Totals.NONE, ReportService::add);
        LocalDate oldest = months.getLast().month().atDay(1);
        List<ReportQueries.AmountOwed> owed = queries.amountsOwed(actor.organisationId(), oldest, scope);
        Map<UUID, UUID> currentClass = currentClasses(owed.stream().map(ReportQueries.AmountOwed::studentId)
                .collect(Collectors.toSet()));
        Map<UUID, String> classNames = classNames(Set.copyOf(currentClass.values()));
        List<PaymentReportResponse.Owing> owing = owed.stream()
                .map(row -> new PaymentReportResponse.Owing(row.studentId(), row.firstName(), row.lastName(),
                        classNames.get(currentClass.get(row.studentId())), row.months(), money(row.owed())))
                .toList();
        return new PaymentReportResponse(currency, months, totals, owing);
    }

    @Transactional(readOnly = true)
    public DashboardResponse dashboard(CurrentUser actor) {
        LocalDate today = calendar.today(actor.organisationId());
        AttendanceReportResponse attendance = attendance(actor, ReportRange.lastFourWeeks(today), null);
        DashboardResponse.Attendance attendanceFigures = new DashboardResponse.Attendance(attendance.from(),
                attendance.to(), attendance.totals().attendancePercentage(), attendance.totals().late(),
                attendance.totals().absent(), attendance.belowThreshold().size(), attendance.thresholdPercentage());

        ProgressReportResponse progress = progress(actor, null);
        DashboardResponse.Progress progressFigures = new DashboardResponse.Progress(
                progress.classes().stream().mapToInt(ProgressReportResponse.ClassRow::targets).sum(),
                progress.classes().stream().mapToInt(ProgressReportResponse.ClassRow::targetsBehind).sum());

        DashboardResponse.Payments paymentFigures = null;
        if (actor.has(Permission.PAYMENT_READ)) {
            paymentFigures = pastMonths(actor).stream().findFirst()
                    .map(month -> new DashboardResponse.Payments(month.month(), month.currency(), month.totals()))
                    .orElse(null);
        }
        return new DashboardResponse(attendanceFigures, progressFigures, paymentFigures);
    }

    /** Months up to and including this one, newest first; a month added ahead of time is not reported yet. */
    private List<PaymentPeriodResponse> pastMonths(CurrentUser actor) {
        YearMonth now = YearMonth.from(calendar.today(actor.organisationId()));
        return payments.periods(actor).stream().filter(p -> !p.month().isAfter(now)).toList();
    }

    ReportQueries.Filter filter(CurrentUser actor, ReportRange range, UUID classId) {
        AccessScope scope = scopes.scopeFor(actor);
        if (classId != null) {
            requireClass(actor, scope, classId);
        }
        return new ReportQueries.Filter(actor.organisationId(), range.from(), range.to(), classId, scope);
    }

    /** A class outside the caller's scope does not exist for them. */
    private ClassGroup requireClass(CurrentUser actor, AccessScope scope, UUID classId) {
        return classes.findInScope(classId, actor.organisationId(), scope.allClasses(), scope.queryClassIds())
                .orElseThrow(() -> new NotFoundException("Class"));
    }

    int threshold(CurrentUser actor) {
        return organisations.findById(actor.organisationId()).map(Organisation::getAttendanceThresholdPct)
                .orElse((short) 80);
    }

    String currency(CurrentUser actor) {
        return organisations.findById(actor.organisationId()).map(Organisation::getCurrency).orElse("GBP");
    }

    Map<UUID, String> classNames(Collection<UUID> ids) {
        if (ids.isEmpty()) {
            return Map.of();
        }
        return classes.findByIdIn(ids).stream().collect(Collectors.toMap(ClassGroup::getId, ClassGroup::getName));
    }

    /** Each student's current class, for students who are in one. */
    Map<UUID, UUID> currentClasses(Collection<UUID> studentIds) {
        if (studentIds.isEmpty()) {
            return Map.of();
        }
        return enrollments.findByStudentIdInAndEndDateIsNull(studentIds).stream()
                .collect(Collectors.toMap(ClassEnrollment::getStudentId, ClassEnrollment::getClassGroupId,
                        (a, b) -> a, LinkedHashMap::new));
    }

    private Map<UUID, Student> studentsById(Collection<UUID> ids) {
        if (ids.isEmpty()) {
            return Map.of();
        }
        return students.findByIdIn(ids).stream().collect(Collectors.toMap(Student::getId, Function.identity()));
    }

    private static boolean isBehind(StudentTarget target) {
        return target.getTargetPercentage() != null && target.getCurrentPercentage() != null
                && target.getCurrentPercentage() < target.getTargetPercentage();
    }

    private record Average(long scores, BigDecimal value) {
    }

    /** The average over all subjects, weighted by how many scores each subject has. */
    private static Average average(List<ReportQueries.ScoreSummary> rows) {
        long scores = rows.stream().mapToLong(ReportQueries.ScoreSummary::scores).sum();
        if (scores == 0) {
            return new Average(0, null);
        }
        double sum = rows.stream().mapToDouble(r -> r.average() * r.scores()).sum();
        return new Average(scores, Figures.averageScore(sum / scores));
    }

    private static PaymentPeriodResponse.Totals add(PaymentPeriodResponse.Totals a, PaymentPeriodResponse.Totals b) {
        return new PaymentPeriodResponse.Totals(a.students() + b.students(), a.paid() + b.paid(),
                a.partiallyPaid() + b.partiallyPaid(), a.outstanding() + b.outstanding(),
                money(a.expectedTotal().add(b.expectedTotal())), money(a.paidTotal().add(b.paidTotal())),
                money(a.outstandingTotal().add(b.outstandingTotal())));
    }

    static BigDecimal money(BigDecimal amount) {
        return (amount == null ? BigDecimal.ZERO : amount).setScale(2, RoundingMode.HALF_UP);
    }

    private static Integer toInteger(Short value) {
        return value == null ? null : value.intValue();
    }
}
