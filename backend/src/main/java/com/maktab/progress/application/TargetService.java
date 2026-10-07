package com.maktab.progress.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.application.AccessScopeService;
import com.maktab.classgroup.domain.ClassEnrollment;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.persistence.ClassEnrollmentRepository;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.common.AccessScope;
import com.maktab.common.BusinessValidationException;
import com.maktab.common.NotFoundException;
import com.maktab.curriculum.api.CurriculumPeriodSummary;
import com.maktab.curriculum.application.CurriculumService;
import com.maktab.curriculum.domain.CurriculumPeriod;
import com.maktab.curriculum.persistence.CurriculumPeriodRepository;
import com.maktab.organisation.application.OrganisationCalendar;
import com.maktab.progress.api.ClassProgressResponse;
import com.maktab.progress.api.TargetRequest;
import com.maktab.progress.api.TargetResponse;
import com.maktab.progress.domain.StudentTarget;
import com.maktab.progress.persistence.StudentProgressRepository;
import com.maktab.progress.persistence.StudentTargetRepository;
import com.maktab.student.application.StudentAccess;
import com.maktab.student.domain.Student;
import com.maktab.student.persistence.StudentRepository;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.HashMap;
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
 * Targets per student and four-week period, and the class overview built on them. A target is set for a period of
 * the student's own class level; targets of earlier periods are kept as they were.
 */
@Service
public class TargetService {

    private static final String ENTITY = "StudentTarget";

    private final StudentTargetRepository targets;
    private final StudentProgressRepository progress;
    private final CurriculumPeriodRepository periods;
    private final CurriculumService curriculum;
    private final ClassGroupRepository classes;
    private final ClassEnrollmentRepository enrollments;
    private final StudentRepository students;
    private final StudentAccess studentAccess;
    private final AccessScopeService scopes;
    private final ProgressScale scale;
    private final OrganisationCalendar calendar;
    private final AuditService audit;

    public TargetService(StudentTargetRepository targets, StudentProgressRepository progress,
            CurriculumPeriodRepository periods, CurriculumService curriculum, ClassGroupRepository classes,
            ClassEnrollmentRepository enrollments, StudentRepository students, StudentAccess studentAccess,
            AccessScopeService scopes, ProgressScale scale, OrganisationCalendar calendar, AuditService audit) {
        this.targets = targets;
        this.progress = progress;
        this.periods = periods;
        this.curriculum = curriculum;
        this.classes = classes;
        this.enrollments = enrollments;
        this.students = students;
        this.studentAccess = studentAccess;
        this.scopes = scopes;
        this.scale = scale;
        this.calendar = calendar;
        this.audit = audit;
    }

    /** All of a student's targets, the latest period first. */
    @Transactional(readOnly = true)
    public List<TargetResponse> forStudent(CurrentUser actor, UUID studentId) {
        studentAccess.requireInScope(actor, studentId);
        return toResponses(actor, targets.findByStudentId(studentId));
    }

    @Transactional
    public TargetResponse create(CurrentUser actor, TargetRequest request) {
        if (request.studentId() == null) {
            throw new BusinessValidationException("studentId", "Student is required");
        }
        if (request.curriculumPeriodId() == null) {
            throw new BusinessValidationException("curriculumPeriodId", "Choose a period");
        }
        studentAccess.requireInScope(actor, request.studentId());
        UUID levelId = enrollments.findByStudentIdAndEndDateIsNull(request.studentId())
                .flatMap(enrollment -> classes.findById(enrollment.getClassGroupId()))
                .map(ClassGroup::getCurriculumLevelId)
                .orElseThrow(() -> new BusinessValidationException("studentId",
                        "A student needs a class before they can have targets"));
        CurriculumPeriod period = periods.findById(request.curriculumPeriodId())
                .filter(p -> p.getCurriculumLevelId().equals(levelId))
                .orElseThrow(() -> new BusinessValidationException("curriculumPeriodId",
                        "Choose a period of the student's own level"));
        StudentTarget target = new StudentTarget(request.studentId(), period.getId(), actor.id());
        apply(actor, target, request);
        targets.save(target);
        audit.record(actor, AuditAction.TARGET_CREATED, ENTITY, target.getId(), null, snapshot(target));
        return toResponses(actor, List.of(target)).getFirst();
    }

    @Transactional
    public TargetResponse update(CurrentUser actor, UUID id, TargetRequest request) {
        StudentTarget target = targets.findById(id).orElseThrow(() -> new NotFoundException(ENTITY));
        try {
            studentAccess.requireInScope(actor, target.getStudentId());
        } catch (NotFoundException outOfScope) {
            // Someone else's student: the target simply does not exist for this caller.
            throw new NotFoundException(ENTITY);
        }
        Map<String, Object> before = snapshot(target);
        apply(actor, target, request);
        targets.flush();
        audit.record(actor, AuditAction.TARGET_UPDATED, ENTITY, id, before, snapshot(target));
        return toResponses(actor, List.of(target)).getFirst();
    }

    /** A class at a glance for the period running today: each student's latest score and their targets. */
    @Transactional(readOnly = true)
    public ClassProgressResponse classOverview(CurrentUser actor, UUID classId) {
        AccessScope scope = scopes.scopeFor(actor);
        ClassGroup classGroup = classes.findInScope(classId, actor.organisationId(), scope.allClasses(),
                        scope.queryClassIds())
                .orElseThrow(() -> new NotFoundException("Class"));
        LocalDate today = calendar.today(actor.organisationId());
        Optional<CurriculumPeriod> period = curriculum.periodOn(classGroup.getCurriculumLevelId(), today);
        Set<UUID> roster = enrollments.findByClassGroupIdAndEndDateIsNull(classId).stream()
                .map(ClassEnrollment::getStudentId).collect(Collectors.toSet());
        if (roster.isEmpty()) {
            return new ClassProgressResponse(classId, classGroup.getName(),
                    period.map(CurriculumPeriodSummary::from).orElse(null), List.of());
        }
        Map<UUID, List<TargetResponse>> targetsByStudent = period
                .map(p -> toResponses(actor, targets.findByCurriculumPeriodIdAndStudentIdIn(p.getId(), roster)))
                .orElseGet(List::of).stream()
                .collect(Collectors.groupingBy(TargetResponse::studentId));
        // The latest score in this period, or in the last four weeks when the class has no period now.
        LocalDate from = period.map(CurriculumPeriod::getStartDate)
                .orElse(today.minusDays(CurriculumPeriod.LENGTH_IN_DAYS));
        ProgressScale.Lookup levels = scale.lookup(actor.organisationId());
        Map<UUID, ClassProgressResponse.LatestScore> latest = new HashMap<>();
        for (StudentProgressRepository.RecentScoreRow row : progress.findRecent(roster, from)) {
            latest.putIfAbsent(row.getStudentId(), new ClassProgressResponse.LatestScore(row.getLessonDate(),
                    row.getSubject(), row.getScore(), levels.labelOf(row.getScore())));
        }
        List<ClassProgressResponse.StudentRow> rows = students.findByIdIn(roster).stream()
                .sorted(Comparator.comparing(Student::getLastName, String.CASE_INSENSITIVE_ORDER)
                        .thenComparing(Student::getFirstName, String.CASE_INSENSITIVE_ORDER))
                .map(s -> new ClassProgressResponse.StudentRow(s.getId(), s.getFirstName(), s.getLastName(),
                        latest.get(s.getId()), targetsByStudent.getOrDefault(s.getId(), List.of())))
                .toList();
        return new ClassProgressResponse(classId, classGroup.getName(),
                period.map(CurriculumPeriodSummary::from).orElse(null), rows);
    }

    private void apply(CurrentUser actor, StudentTarget target, TargetRequest request) {
        BigDecimal score = null;
        if (request.progressScore() != null) {
            score = scale.lookup(actor.organisationId()).find(request.progressScore())
                    .orElseThrow(() -> new BusinessValidationException("progressScore",
                            "Choose a score from the progress scale"))
                    .getScore();
        }
        target.update(request.subject(), request.description().trim(), request.targetPercentage(),
                request.currentPercentage(), score, blankToNull(request.teacherNote()), actor.id());
    }

    private List<TargetResponse> toResponses(CurrentUser actor, List<StudentTarget> list) {
        Map<UUID, CurriculumPeriod> periodById = periods.findByIdIn(list.stream()
                        .map(StudentTarget::getCurriculumPeriodId).collect(Collectors.toSet())).stream()
                .collect(Collectors.toMap(CurriculumPeriod::getId, Function.identity()));
        ProgressScale.Lookup levels = scale.lookup(actor.organisationId());
        return list.stream()
                .sorted(Comparator.comparing((StudentTarget t) -> periodById.get(t.getCurriculumPeriodId())
                        .getStartDate()).reversed())
                .map(t -> new TargetResponse(t.getId(), t.getStudentId(),
                        CurriculumPeriodSummary.from(periodById.get(t.getCurriculumPeriodId())), t.getSubject(),
                        t.getDescription(), toInteger(t.getTargetPercentage()), toInteger(t.getCurrentPercentage()),
                        t.getProgressScore(), levels.labelOf(t.getProgressScore()), t.getTeacherNote()))
                .toList();
    }

    private static Map<String, Object> snapshot(StudentTarget target) {
        Map<String, Object> values = new HashMap<>();
        values.put("studentId", target.getStudentId());
        values.put("curriculumPeriodId", target.getCurriculumPeriodId());
        values.put("description", target.getDescription());
        values.put("targetPercentage", target.getTargetPercentage());
        values.put("currentPercentage", target.getCurrentPercentage());
        values.put("progressScore", target.getProgressScore());
        return values;
    }

    private static Integer toInteger(Short value) {
        return value == null ? null : value.intValue();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
