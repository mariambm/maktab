package com.maktab.lesson.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.domain.ClassEnrollment;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.domain.ClassSchedule;
import com.maktab.classgroup.persistence.ClassEnrollmentRepository;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.classgroup.persistence.ClassScheduleRepository;
import com.maktab.classgroup.application.AccessScopeService;
import com.maktab.common.AccessScope;
import com.maktab.common.BusinessValidationException;
import com.maktab.common.NotFoundException;
import com.maktab.common.PageResponse;
import com.maktab.curriculum.api.CurriculumPeriodSummary;
import com.maktab.curriculum.api.LessonTopicResponse;
import com.maktab.curriculum.application.CurriculumService;
import com.maktab.curriculum.domain.CurriculumPeriod;
import com.maktab.lesson.api.AttendanceEntryRequest;
import com.maktab.lesson.api.LessonDetailResponse;
import com.maktab.lesson.api.LessonStudentResponse;
import com.maktab.lesson.api.LessonSummaryResponse;
import com.maktab.lesson.api.OpenLessonRequest;
import com.maktab.lesson.api.UpdateLessonRequest;
import com.maktab.lesson.domain.Lesson;
import com.maktab.lesson.domain.LessonAttendance;
import com.maktab.lesson.domain.LessonStatus;
import com.maktab.lesson.domain.LessonTopicCovered;
import com.maktab.lesson.persistence.LessonAttendanceRepository;
import com.maktab.lesson.persistence.LessonRepository;
import com.maktab.lesson.persistence.LessonTopicCoveredRepository;
import com.maktab.organisation.application.OrganisationCalendar;
import com.maktab.student.domain.Student;
import com.maktab.student.persistence.StudentRepository;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * The teacher's workflow: see today's lessons, open one, record what was taught and who was there. Every read and
 * write is limited to the caller's access scope, so a teacher cannot reach another class's lesson by its id.
 */
@Service
public class LessonService {

    private static final String ENTITY = "Lesson";

    private final LessonRepository lessons;
    private final LessonAttendanceRepository attendance;
    private final LessonTopicCoveredRepository coveredTopics;
    private final ClassGroupRepository classes;
    private final ClassScheduleRepository schedules;
    private final ClassEnrollmentRepository enrollments;
    private final StudentRepository students;
    private final CurriculumService curriculum;
    private final AccessScopeService scopes;
    private final OrganisationCalendar calendar;
    private final AuditService audit;

    public LessonService(LessonRepository lessons, LessonAttendanceRepository attendance,
            LessonTopicCoveredRepository coveredTopics, ClassGroupRepository classes,
            ClassScheduleRepository schedules, ClassEnrollmentRepository enrollments, StudentRepository students,
            CurriculumService curriculum, AccessScopeService scopes, OrganisationCalendar calendar,
            AuditService audit) {
        this.lessons = lessons;
        this.attendance = attendance;
        this.coveredTopics = coveredTopics;
        this.classes = classes;
        this.schedules = schedules;
        this.enrollments = enrollments;
        this.students = students;
        this.curriculum = curriculum;
        this.scopes = scopes;
        this.calendar = calendar;
        this.audit = audit;
    }

    /**
     * The lessons of {@code date} for the caller's classes: the scheduled slots plus any lesson already opened,
     * including lessons outside the weekly schedule. Slots that have not been opened yet have no id.
     */
    @Transactional(readOnly = true)
    public List<LessonSummaryResponse> onDate(CurrentUser actor, LocalDate date) {
        LocalDate day = date == null ? calendar.today(actor.organisationId()) : date;
        AccessScope scope = scopes.scopeFor(actor);
        List<ClassGroup> myClasses = classesInScope(actor, scope);
        Set<UUID> classIds = myClasses.stream().map(ClassGroup::getId).collect(Collectors.toSet());
        if (classIds.isEmpty()) {
            return List.of();
        }
        Map<UUID, ClassGroup> classById = myClasses.stream()
                .collect(Collectors.toMap(ClassGroup::getId, Function.identity()));
        List<Lesson> opened = lessons.findByClassGroupIdInAndLessonDate(classIds, day);
        Set<String> openedSlots = opened.stream().map(LessonService::slotKey).collect(Collectors.toSet());
        Map<UUID, Long> enrolled = enrolledCounts(classIds);
        Map<UUID, Long> recorded = attendance.findByLessonIdIn(opened.stream().map(Lesson::getId).toList()).stream()
                .collect(Collectors.groupingBy(LessonAttendance::getLessonId, Collectors.counting()));

        List<LessonSummaryResponse> result = new ArrayList<>();
        for (Lesson lesson : opened) {
            ClassGroup classGroup = classById.get(lesson.getClassGroupId());
            result.add(new LessonSummaryResponse(lesson.getId(), classGroup.getId(), classGroup.getName(),
                    classGroup.getRoom(), lesson.getLessonDate(), lesson.getStartTime(), lesson.getEndTime(),
                    lesson.getStatus(), lesson.getClassScheduleId(), enrolled.getOrDefault(classGroup.getId(), 0L),
                    recorded.getOrDefault(lesson.getId(), 0L)));
        }
        for (ClassSchedule slot : schedules.findByClassGroupIdInOrderByWeekdayAscStartTimeAsc(classIds)) {
            ClassGroup classGroup = classById.get(slot.getClassGroupId());
            if (slot.getWeekday() != day.getDayOfWeek() || !classGroup.isActive()
                    || openedSlots.contains(slotKey(slot.getClassGroupId(), slot.getStartTime()))) {
                continue;
            }
            result.add(new LessonSummaryResponse(null, classGroup.getId(), classGroup.getName(), classGroup.getRoom(),
                    day, slot.getStartTime(), slot.getEndTime(), LessonStatus.PLANNED, slot.getId(),
                    enrolled.getOrDefault(classGroup.getId(), 0L), 0L));
        }
        result.sort(Comparator.comparing(LessonSummaryResponse::startTime)
                .thenComparing(LessonSummaryResponse::className));
        return result;
    }

    @Transactional(readOnly = true)
    public PageResponse<LessonSummaryResponse> search(CurrentUser actor, UUID classId, LocalDate from, LocalDate to,
            Pageable pageable) {
        AccessScope scope = scopes.scopeFor(actor);
        Page<Lesson> page = lessons.search(classId, from, to, scope.allClasses(), scope.queryClassIds(), pageable);
        Map<UUID, ClassGroup> classById = classes.findByIdIn(page.getContent().stream()
                        .map(Lesson::getClassGroupId).collect(Collectors.toSet())).stream()
                .collect(Collectors.toMap(ClassGroup::getId, Function.identity()));
        Map<UUID, Long> enrolled = enrolledCounts(classById.keySet());
        Map<UUID, Long> recorded = attendance.findByLessonIdIn(page.getContent().stream().map(Lesson::getId).toList())
                .stream().collect(Collectors.groupingBy(LessonAttendance::getLessonId, Collectors.counting()));
        List<LessonSummaryResponse> items = page.getContent().stream().map(lesson -> {
            ClassGroup classGroup = classById.get(lesson.getClassGroupId());
            return new LessonSummaryResponse(lesson.getId(), classGroup.getId(), classGroup.getName(),
                    classGroup.getRoom(), lesson.getLessonDate(), lesson.getStartTime(), lesson.getEndTime(),
                    lesson.getStatus(), lesson.getClassScheduleId(), enrolled.getOrDefault(classGroup.getId(), 0L),
                    recorded.getOrDefault(lesson.getId(), 0L));
        }).toList();
        return new PageResponse<>(items, page.getNumber(), page.getSize(), page.getTotalElements());
    }

    @Transactional(readOnly = true)
    public LessonDetailResponse get(CurrentUser actor, UUID id) {
        return toDetail(actor, loadInScope(actor, id));
    }

    /**
     * Opens the lesson for a class, date and slot, creating it the first time and returning the existing one
     * afterwards, so a teacher tapping twice never creates two lessons.
     */
    @Transactional
    public LessonDetailResponse open(CurrentUser actor, OpenLessonRequest request) {
        ClassGroup classGroup = loadClassInScope(actor, request.classGroupId());
        LocalDate date = request.lessonDate();
        if (date.isAfter(calendar.today(actor.organisationId()))) {
            throw new BusinessValidationException("lessonDate", "A lesson cannot be opened before its date");
        }
        LocalTime start;
        LocalTime end;
        UUID scheduleId = request.classScheduleId();
        if (scheduleId != null) {
            ClassSchedule slot = schedules.findById(scheduleId)
                    .filter(s -> s.getClassGroupId().equals(classGroup.getId()))
                    .orElseThrow(() -> new BusinessValidationException("classScheduleId", "Slot not found"));
            if (slot.getWeekday() != date.getDayOfWeek()) {
                throw new BusinessValidationException("lessonDate", "This slot is not on that day");
            }
            start = slot.getStartTime();
            end = slot.getEndTime();
        } else {
            start = request.startTime();
            end = request.endTime();
            if (start == null || end == null || !end.isAfter(start)) {
                throw new BusinessValidationException("startTime", "Enter a start and end time");
            }
        }
        Lesson lesson = lessons.findByClassGroupIdAndLessonDateAndStartTime(classGroup.getId(), date, start)
                .orElseGet(() -> {
                    Lesson created = lessons.save(
                            new Lesson(classGroup.getId(), scheduleId, date, start, end, actor.id()));
                    audit.record(actor, AuditAction.LESSON_OPENED, ENTITY, created.getId(), null,
                            Map.of("classGroupId", classGroup.getId(), "lessonDate", date, "startTime", start));
                    return created;
                });
        return toDetail(actor, lesson);
    }

    @Transactional
    public LessonDetailResponse update(CurrentUser actor, UUID id, UpdateLessonRequest request) {
        Lesson lesson = loadInScope(actor, id);
        Map<String, Object> before = Map.of("status", lesson.getStatus(), "contentNotes",
                String.valueOf(lesson.getContentNotes()), "topics", coveredTopicIds(lesson.getId()));
        LocalTime end = request.endTime() == null ? lesson.getEndTime() : request.endTime();
        if (!end.isAfter(lesson.getStartTime())) {
            throw new BusinessValidationException("endTime", "End time must be after the start time");
        }
        lesson.update(end, blankToNull(request.contentNotes()), request.status(), lesson.getTeacherUserId());
        replaceCoveredTopics(actor, lesson, request.coveredTopicIdsOrEmpty());
        audit.record(actor, AuditAction.LESSON_UPDATED, ENTITY, id, before,
                Map.of("status", request.status(), "contentNotes", String.valueOf(request.contentNotes()),
                        "topics", request.asList()));
        return toDetail(actor, lesson);
    }

    /** Saves the whole register in one go. Students not in the class now are rejected. */
    @Transactional
    public LessonDetailResponse recordAttendance(CurrentUser actor, UUID id, List<AttendanceEntryRequest> entries) {
        Lesson lesson = loadInScope(actor, id);
        Set<UUID> roster = rosterIds(lesson.getClassGroupId());
        Set<UUID> seen = new HashSet<>();
        for (AttendanceEntryRequest entry : entries) {
            if (!roster.contains(entry.studentId())) {
                throw new BusinessValidationException("entries", "A student in the register is not in this class");
            }
            if (!seen.add(entry.studentId())) {
                throw new BusinessValidationException("entries", "A student appears twice in the register");
            }
        }
        Map<UUID, LessonAttendance> existing = attendance.findByLessonId(id).stream()
                .collect(Collectors.toMap(LessonAttendance::getStudentId, Function.identity()));
        for (AttendanceEntryRequest entry : entries) {
            LessonAttendance record = existing.get(entry.studentId());
            boolean isNew = record == null;
            if (isNew) {
                record = new LessonAttendance(id, entry.studentId(), actor.id());
            }
            record.record(entry.status(), entry.minutesLate(), entry.absenceReason(), blankToNull(entry.note()),
                    actor.id());
            if (isNew) {
                // Saved only once the record is complete: a new row is inserted with the state it has at save time.
                existing.put(entry.studentId(), attendance.save(record));
            }
        }
        attendance.flush();
        audit.record(actor, AuditAction.ATTENDANCE_RECORDED, ENTITY, id, null,
                Map.of("students", entries.size(), "lessonDate", lesson.getLessonDate()));
        return toDetail(actor, lesson);
    }

    private void replaceCoveredTopics(CurrentUser actor, Lesson lesson, Set<UUID> topicIds) {
        coveredTopics.deleteByIdLessonId(lesson.getId());
        coveredTopics.flush();
        if (topicIds.isEmpty()) {
            return;
        }
        ClassGroup classGroup = classes.findById(lesson.getClassGroupId()).orElseThrow();
        CurriculumPeriod period = curriculum
                .periodOn(classGroup.getCurriculumLevelId(), lesson.getLessonDate())
                .orElseThrow(() -> new BusinessValidationException("coveredTopicIds",
                        "This class has no curriculum period for this date"));
        curriculum.requireTopicsInPeriod(topicIds, period.getId());
        topicIds.forEach(topicId -> coveredTopics.save(new LessonTopicCovered(lesson.getId(), topicId)));
        coveredTopics.flush();
    }

    private LessonDetailResponse toDetail(CurrentUser actor, Lesson lesson) {
        ClassGroup classGroup = classes.findById(lesson.getClassGroupId()).orElseThrow();
        Optional<CurriculumPeriod> period =
                curriculum.periodOn(classGroup.getCurriculumLevelId(), lesson.getLessonDate());
        List<LessonTopicResponse> topics = period
                .map(p -> curriculum.topicsForWeekOf(p, lesson.getLessonDate()))
                .orElseGet(List::of);
        Map<UUID, LessonAttendance> recorded = attendance.findByLessonId(lesson.getId()).stream()
                .collect(Collectors.toMap(LessonAttendance::getStudentId, Function.identity()));
        List<LessonStudentResponse> roster = students.findByIdIn(rosterIds(lesson.getClassGroupId())).stream()
                .sorted(Comparator.comparing(Student::getLastName, String.CASE_INSENSITIVE_ORDER)
                        .thenComparing(Student::getFirstName, String.CASE_INSENSITIVE_ORDER))
                .map(student -> {
                    LessonAttendance a = recorded.get(student.getId());
                    return new LessonStudentResponse(student.getId(), student.getFirstName(), student.getLastName(),
                            a == null ? null : a.getStatus(),
                            a == null || a.getMinutesLate() == null ? null : (int) a.getMinutesLate(),
                            a == null ? null : a.getAbsenceReason(), a == null ? null : a.getNote());
                })
                .toList();
        return new LessonDetailResponse(lesson.getId(), classGroup.getId(), classGroup.getName(),
                classGroup.getRoom(), lesson.getLessonDate(), lesson.getStartTime(), lesson.getEndTime(),
                lesson.getStatus(), lesson.getContentNotes(), lesson.getTeacherUserId(),
                period.map(CurriculumPeriodSummary::from).orElse(null),
                period.flatMap(p -> p.weekNumberOn(lesson.getLessonDate())).orElse(null),
                topics, coveredTopicIds(lesson.getId()), roster);
    }

    private List<UUID> coveredTopicIds(UUID lessonId) {
        return coveredTopics.findByIdLessonId(lessonId).stream().map(LessonTopicCovered::getLessonTopicId).toList();
    }

    private Set<UUID> rosterIds(UUID classGroupId) {
        return enrollments.findByClassGroupIdAndEndDateIsNull(classGroupId).stream()
                .map(ClassEnrollment::getStudentId).collect(Collectors.toSet());
    }

    private Map<UUID, Long> enrolledCounts(Set<UUID> classIds) {
        return classIds.isEmpty() ? Map.of()
                : enrollments.countCurrentStudents(classIds).stream()
                        .collect(Collectors.toMap(ClassEnrollmentRepository.ClassCount::getClassGroupId,
                                ClassEnrollmentRepository.ClassCount::getStudents));
    }

    private List<ClassGroup> classesInScope(CurrentUser actor, AccessScope scope) {
        if (scope.allClasses()) {
            return classes.findByOrganisationIdAndActiveTrue(actor.organisationId());
        }
        return classes.findByIdIn(scope.classIds());
    }

    private Lesson loadInScope(CurrentUser actor, UUID id) {
        AccessScope scope = scopes.scopeFor(actor);
        return lessons.findInScope(id, scope.allClasses(), scope.queryClassIds())
                .orElseThrow(() -> new NotFoundException(ENTITY));
    }

    private ClassGroup loadClassInScope(CurrentUser actor, UUID classGroupId) {
        AccessScope scope = scopes.scopeFor(actor);
        return classes.findInScope(classGroupId, actor.organisationId(), scope.allClasses(), scope.queryClassIds())
                .orElseThrow(() -> new NotFoundException("Class"));
    }

    private static String slotKey(Lesson lesson) {
        return slotKey(lesson.getClassGroupId(), lesson.getStartTime());
    }

    private static String slotKey(UUID classGroupId, LocalTime startTime) {
        return classGroupId + "@" + startTime;
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
