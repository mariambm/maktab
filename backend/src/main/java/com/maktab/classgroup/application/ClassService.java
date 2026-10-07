package com.maktab.classgroup.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.api.ClassRequest;
import com.maktab.classgroup.api.ClassResponse;
import com.maktab.classgroup.api.ClassStudentResponse;
import com.maktab.classgroup.api.CreateCurriculumLevelRequest;
import com.maktab.classgroup.api.CurriculumLevelResponse;
import com.maktab.classgroup.api.ScheduleSlot;
import com.maktab.classgroup.api.TeacherRef;
import com.maktab.classgroup.domain.ClassEnrollment;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.domain.ClassSchedule;
import com.maktab.classgroup.domain.ClassTeacher;
import com.maktab.classgroup.domain.CurriculumLevel;
import com.maktab.classgroup.persistence.ClassEnrollmentRepository;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.classgroup.persistence.ClassScheduleRepository;
import com.maktab.classgroup.persistence.ClassTeacherRepository;
import com.maktab.classgroup.persistence.CurriculumLevelRepository;
import com.maktab.common.AccessScope;
import com.maktab.common.BusinessValidationException;
import com.maktab.common.ConflictException;
import com.maktab.common.NotFoundException;
import com.maktab.common.PageResponse;
import com.maktab.common.SearchTerms;
import com.maktab.organisation.application.OrganisationCalendar;
import com.maktab.student.domain.Student;
import com.maktab.student.persistence.StudentRepository;
import com.maktab.user.domain.Role;
import com.maktab.user.domain.User;
import com.maktab.user.persistence.UserRepository;
import java.time.LocalDate;
import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Classes, curriculum levels, weekly schedules and teacher assignments. Reads are limited to the caller's scope. */
@Service
public class ClassService {

    private static final String ENTITY = "ClassGroup";

    private final ClassGroupRepository classes;
    private final CurriculumLevelRepository levels;
    private final ClassScheduleRepository schedules;
    private final ClassTeacherRepository classTeachers;
    private final ClassEnrollmentRepository enrollments;
    private final StudentRepository students;
    private final UserRepository users;
    private final AccessScopeService scopes;
    private final OrganisationCalendar calendar;
    private final AuditService audit;

    public ClassService(ClassGroupRepository classes, CurriculumLevelRepository levels,
            ClassScheduleRepository schedules, ClassTeacherRepository classTeachers,
            ClassEnrollmentRepository enrollments, StudentRepository students, UserRepository users,
            AccessScopeService scopes, OrganisationCalendar calendar, AuditService audit) {
        this.classes = classes;
        this.levels = levels;
        this.schedules = schedules;
        this.classTeachers = classTeachers;
        this.enrollments = enrollments;
        this.students = students;
        this.users = users;
        this.scopes = scopes;
        this.calendar = calendar;
        this.audit = audit;
    }

    // Curriculum levels

    @Transactional(readOnly = true)
    public List<CurriculumLevelResponse> levels(CurrentUser actor) {
        return levels.findByOrganisationIdOrderBySortOrderAscNameAsc(actor.organisationId()).stream()
                .map(CurriculumLevelResponse::from).toList();
    }

    @Transactional
    public CurriculumLevelResponse createLevel(CurrentUser actor, CreateCurriculumLevelRequest request) {
        String name = request.name().trim();
        if (levels.existsByOrganisationIdAndNameIgnoreCase(actor.organisationId(), name)) {
            throw new ConflictException("A curriculum level with this name already exists");
        }
        short order = request.sortOrder() == null ? 0 : request.sortOrder().shortValue();
        CurriculumLevel level = levels.save(new CurriculumLevel(actor.organisationId(), name, order));
        CurriculumLevelResponse response = CurriculumLevelResponse.from(level);
        audit.record(actor, AuditAction.CURRICULUM_LEVEL_CREATED, "CurriculumLevel", level.getId(), null, response);
        return response;
    }

    // Classes

    @Transactional(readOnly = true)
    public PageResponse<ClassResponse> search(CurrentUser actor, String search, UUID levelId, Boolean active,
            Pageable pageable) {
        AccessScope scope = scopes.scopeFor(actor);
        Page<ClassGroup> page = classes.search(actor.organisationId(), SearchTerms.containsPattern(search), levelId,
                active, scope.allClasses(), scope.queryClassIds(), pageable);
        List<ClassResponse> items = toResponses(page.getContent());
        return new PageResponse<>(items, page.getNumber(), page.getSize(), page.getTotalElements());
    }

    @Transactional(readOnly = true)
    public ClassResponse get(CurrentUser actor, UUID id) {
        return toResponse(loadInScope(actor, id));
    }

    @Transactional(readOnly = true)
    public List<ClassStudentResponse> currentStudents(CurrentUser actor, UUID id) {
        ClassGroup classGroup = loadInScope(actor, id);
        List<ClassEnrollment> open = enrollments.findByClassGroupIdAndEndDateIsNull(classGroup.getId());
        Map<UUID, LocalDate> since = open.stream()
                .collect(Collectors.toMap(ClassEnrollment::getStudentId, ClassEnrollment::getStartDate));
        return students.findByIdIn(since.keySet()).stream()
                .sorted(Comparator.comparing(Student::getLastName, String.CASE_INSENSITIVE_ORDER)
                        .thenComparing(Student::getFirstName, String.CASE_INSENSITIVE_ORDER))
                .map(s -> new ClassStudentResponse(s.getId(), s.getFirstName(), s.getLastName(), s.getDateOfBirth(),
                        since.get(s.getId())))
                .toList();
    }

    @Transactional
    public ClassResponse create(CurrentUser actor, ClassRequest request) {
        String name = request.name().trim();
        requireLevel(actor, request.curriculumLevelId());
        if (classes.existsByOrganisationIdAndNameIgnoreCase(actor.organisationId(), name)) {
            throw new ConflictException("A class with this name already exists");
        }
        ClassGroup classGroup = new ClassGroup(actor.organisationId(), request.curriculumLevelId(), name,
                blankToNull(request.room()));
        if (Boolean.FALSE.equals(request.active())) {
            classGroup.update(request.curriculumLevelId(), name, classGroup.getRoom(), false);
        }
        classes.save(classGroup);
        ClassResponse response = toResponse(classGroup);
        audit.record(actor, AuditAction.CLASS_CREATED, ENTITY, classGroup.getId(), null, response);
        return response;
    }

    @Transactional
    public ClassResponse update(CurrentUser actor, UUID id, ClassRequest request) {
        ClassGroup classGroup = load(actor, id);
        ClassResponse before = toResponse(classGroup);
        String name = request.name().trim();
        requireLevel(actor, request.curriculumLevelId());
        if (!name.equalsIgnoreCase(classGroup.getName())
                && classes.existsByOrganisationIdAndNameIgnoreCase(actor.organisationId(), name)) {
            throw new ConflictException("A class with this name already exists");
        }
        boolean active = !Boolean.FALSE.equals(request.active());
        if (!active && classGroup.isActive()) {
            int enrolled = enrollments.findByClassGroupIdAndEndDateIsNull(id).size();
            if (enrolled > 0) {
                throw new BusinessValidationException("active",
                        "Move the " + enrolled + " student(s) in this class to another class first");
            }
        }
        classGroup.update(request.curriculumLevelId(), name, blankToNull(request.room()), active);
        ClassResponse after = toResponse(classGroup);
        audit.record(actor, AuditAction.CLASS_UPDATED, ENTITY, id, before, after);
        return after;
    }

    /**
     * Makes {@code teacherIds} the class's current teachers. Removed teachers' assignments end today (their access
     * ends with them); new teachers start today. Unchanged assignments keep their original start date.
     */
    @Transactional
    public ClassResponse replaceTeachers(CurrentUser actor, UUID id, Set<UUID> teacherIds) {
        ClassGroup classGroup = load(actor, id);
        List<User> teachers = users.findByIdInAndOrganisationId(teacherIds, actor.organisationId());
        if (teachers.size() != teacherIds.size()
                || !teachers.stream().allMatch(u -> u.isActive() && u.hasRole(Role.TEACHER))) {
            throw new BusinessValidationException("teacherIds", "Choose active teachers only");
        }
        LocalDate today = calendar.today(actor.organisationId());
        List<ClassTeacher> current = classTeachers.findByClassGroupIdAndEndDateIsNull(id);
        Set<UUID> before = current.stream().map(ClassTeacher::getTeacherUserId).collect(Collectors.toSet());
        current.stream().filter(a -> !teacherIds.contains(a.getTeacherUserId())).forEach(a -> a.end(today));
        classTeachers.flush();
        Set<UUID> added = new HashSet<>(teacherIds);
        added.removeAll(before);
        added.forEach(teacherId -> classTeachers.save(new ClassTeacher(id, teacherId, today)));
        audit.record(actor, AuditAction.CLASS_TEACHERS_CHANGED, ENTITY, id, Map.of("teacherIds", before),
                Map.of("teacherIds", teacherIds));
        return toResponse(classGroup);
    }

    @Transactional
    public ClassResponse replaceSchedule(CurrentUser actor, UUID id, List<ScheduleSlot> slots) {
        ClassGroup classGroup = load(actor, id);
        Set<String> seen = new HashSet<>();
        for (ScheduleSlot slot : slots) {
            if (!seen.add(slot.weekday() + "@" + slot.startTime())) {
                throw new BusinessValidationException("slots", "Two slots start at the same day and time");
            }
        }
        List<ScheduleSlot> before = schedules.findByClassGroupIdInOrderByWeekdayAscStartTimeAsc(List.of(id))
                .stream().map(ScheduleSlot::from).toList();
        schedules.deleteByClassGroupId(id);
        slots.forEach(slot -> schedules.save(new ClassSchedule(id, slot.weekday(), slot.startTime(), slot.endTime())));
        schedules.flush();
        ClassResponse after = toResponse(classGroup);
        audit.record(actor, AuditAction.CLASS_SCHEDULE_CHANGED, ENTITY, id, Map.of("schedule", before),
                Map.of("schedule", after.schedule()));
        return after;
    }

    /** Active teachers that can be assigned to a class. */
    @Transactional(readOnly = true)
    public List<TeacherRef> teacherOptions(CurrentUser actor) {
        return users.findActiveWithRole(actor.organisationId(), Role.TEACHER).stream().map(TeacherRef::from).toList();
    }

    private ClassGroup loadInScope(CurrentUser actor, UUID id) {
        AccessScope scope = scopes.scopeFor(actor);
        return classes.findInScope(id, actor.organisationId(), scope.allClasses(), scope.queryClassIds())
                .orElseThrow(() -> new NotFoundException("Class"));
    }

    private ClassGroup load(CurrentUser actor, UUID id) {
        return classes.findByIdAndOrganisationId(id, actor.organisationId())
                .orElseThrow(() -> new NotFoundException("Class"));
    }

    private void requireLevel(CurrentUser actor, UUID levelId) {
        if (levels.findByIdAndOrganisationId(levelId, actor.organisationId()).isEmpty()) {
            throw new BusinessValidationException("curriculumLevelId", "Curriculum level not found");
        }
    }

    private ClassResponse toResponse(ClassGroup classGroup) {
        return toResponses(List.of(classGroup)).getFirst();
    }

    /** Builds responses for a page of classes with one query per related table, not one per class. */
    private List<ClassResponse> toResponses(List<ClassGroup> page) {
        if (page.isEmpty()) {
            return List.of();
        }
        Set<UUID> ids = page.stream().map(ClassGroup::getId).collect(Collectors.toSet());
        Map<UUID, CurriculumLevel> levelById = levels.findByIdIn(
                        page.stream().map(ClassGroup::getCurriculumLevelId).collect(Collectors.toSet()))
                .stream().collect(Collectors.toMap(CurriculumLevel::getId, Function.identity()));
        Map<UUID, Long> counts = enrollments.countCurrentStudents(ids).stream()
                .collect(Collectors.toMap(ClassEnrollmentRepository.ClassCount::getClassGroupId,
                        ClassEnrollmentRepository.ClassCount::getStudents));
        Map<UUID, List<ScheduleSlot>> slots = schedules.findByClassGroupIdInOrderByWeekdayAscStartTimeAsc(ids)
                .stream().collect(Collectors.groupingBy(ClassSchedule::getClassGroupId,
                        Collectors.mapping(ScheduleSlot::from, Collectors.toList())));
        List<ClassTeacher> assignments = classTeachers.findByClassGroupIdInAndEndDateIsNull(ids);
        Map<UUID, User> teacherById = teachersById(assignments.stream().map(ClassTeacher::getTeacherUserId)
                .collect(Collectors.toSet()));
        Map<UUID, List<TeacherRef>> teachers = assignments.stream()
                .collect(Collectors.groupingBy(ClassTeacher::getClassGroupId, Collectors.mapping(
                        a -> TeacherRef.from(teacherById.get(a.getTeacherUserId())), Collectors.toList())));
        return page.stream().map(c -> new ClassResponse(c.getId(), c.getName(),
                CurriculumLevelResponse.from(levelById.get(c.getCurriculumLevelId())), c.getRoom(), c.isActive(),
                counts.getOrDefault(c.getId(), 0L),
                teachers.getOrDefault(c.getId(), List.of()).stream()
                        .sorted(Comparator.comparing(TeacherRef::lastName)).toList(),
                slots.getOrDefault(c.getId(), List.of()))).toList();
    }

    private Map<UUID, User> teachersById(Collection<UUID> ids) {
        return ids.isEmpty() ? Map.of()
                : users.findAllById(ids).stream().collect(Collectors.toMap(User::getId, Function.identity()));
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
