package com.maktab.student.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.api.ClassRef;
import com.maktab.classgroup.api.EnrollmentResponse;
import com.maktab.classgroup.application.AccessScopeService;
import com.maktab.classgroup.application.EnrollmentService;
import com.maktab.common.AccessScope;
import com.maktab.common.BusinessValidationException;
import com.maktab.common.NotFoundException;
import com.maktab.common.PageResponse;
import com.maktab.common.SearchTerms;
import com.maktab.organisation.application.OrganisationCalendar;
import com.maktab.parent.domain.ParentGuardian;
import com.maktab.parent.persistence.ParentGuardianRepository;
import com.maktab.student.api.CreateStudentRequest;
import com.maktab.student.api.ParentLinkRequest;
import com.maktab.student.api.StudentParentResponse;
import com.maktab.student.api.StudentResponse;
import com.maktab.student.api.StudentSummaryResponse;
import com.maktab.student.api.UpdateStudentRequest;
import com.maktab.student.domain.Student;
import com.maktab.student.domain.StudentParent;
import com.maktab.student.domain.StudentStatus;
import com.maktab.student.persistence.StudentParentRepository;
import com.maktab.student.persistence.StudentRepository;
import com.maktab.user.domain.Permission;
import java.time.LocalDate;
import java.util.Comparator;
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

/**
 * Students, their parents and their class. Every lookup goes through the caller's {@link AccessScope}: a teacher
 * only finds students currently in one of their classes, and any other id is answered with 404.
 */
@Service
public class StudentService {

    private static final String ENTITY = "Student";

    private final StudentRepository students;
    private final StudentParentRepository links;
    private final ParentGuardianRepository parents;
    private final EnrollmentService enrollments;
    private final AccessScopeService scopes;
    private final OrganisationCalendar calendar;
    private final AuditService audit;

    public StudentService(StudentRepository students, StudentParentRepository links,
            ParentGuardianRepository parents, EnrollmentService enrollments, AccessScopeService scopes,
            OrganisationCalendar calendar, AuditService audit) {
        this.students = students;
        this.links = links;
        this.parents = parents;
        this.enrollments = enrollments;
        this.scopes = scopes;
        this.calendar = calendar;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public PageResponse<StudentSummaryResponse> search(CurrentUser actor, String search, UUID classId,
            StudentStatus status, Pageable pageable) {
        AccessScope scope = scopes.scopeFor(actor);
        Page<Student> page = students.search(actor.organisationId(), SearchTerms.containsPattern(search), status,
                classId, scope.allClasses(), scope.queryClassIds(), pageable);
        Map<UUID, ClassRef> classes = enrollments.currentClasses(
                page.getContent().stream().map(Student::getId).toList());
        return PageResponse.of(page, s -> new StudentSummaryResponse(s.getId(), s.getFirstName(), s.getLastName(),
                s.getDateOfBirth(), s.getStatus(), classes.get(s.getId())));
    }

    @Transactional(readOnly = true)
    public StudentResponse get(CurrentUser actor, UUID id) {
        return toResponse(actor, loadInScope(actor, id));
    }

    @Transactional
    public StudentResponse create(CurrentUser actor, CreateStudentRequest request) {
        LocalDate today = calendar.today(actor.organisationId());
        LocalDate joinedOn = request.joinedOn() == null ? today : request.joinedOn();
        if (!joinedOn.isAfter(request.dateOfBirth())) {
            throw new BusinessValidationException("joinedOn", "Join date must be after the date of birth");
        }
        Student student = students.save(new Student(actor.organisationId(), request.firstName().trim(),
                request.lastName().trim(), request.dateOfBirth(), request.gender(), joinedOn,
                blankToNull(request.notes())));
        students.flush();
        if (request.parents() != null && !request.parents().isEmpty()) {
            saveLinks(actor, student.getId(), request.parents());
        }
        if (request.classId() != null) {
            enrollments.enrol(actor, student.getId(), request.classId(), joinedOn);
        }
        StudentResponse response = toResponse(actor, student);
        audit.record(actor, AuditAction.STUDENT_CREATED, ENTITY, student.getId(), null, response);
        return response;
    }

    @Transactional
    public StudentResponse update(CurrentUser actor, UUID id, UpdateStudentRequest request) {
        Student student = loadInScope(actor, id);
        StudentResponse before = toResponse(actor, student);
        if (!request.joinedOn().isAfter(request.dateOfBirth())) {
            throw new BusinessValidationException("joinedOn", "Join date must be after the date of birth");
        }
        if (student.getLeftOn() != null && request.joinedOn().isAfter(student.getLeftOn())) {
            throw new BusinessValidationException("joinedOn", "Join date must be on or before the leave date");
        }
        student.updateDetails(request.firstName().trim(), request.lastName().trim(), request.dateOfBirth(),
                request.gender(), request.joinedOn(), blankToNull(request.notes()));
        StudentResponse after = toResponse(actor, student);
        audit.record(actor, AuditAction.STUDENT_UPDATED, ENTITY, id, before, after);
        return after;
    }

    /** Deactivating ends the student's current class today; history stays. Reactivating does not re-enrol. */
    @Transactional
    public StudentResponse setStatus(CurrentUser actor, UUID id, StudentStatus status) {
        Student student = loadInScope(actor, id);
        if (student.getStatus() == status) {
            return toResponse(actor, student);
        }
        LocalDate today = calendar.today(actor.organisationId());
        if (status == StudentStatus.INACTIVE) {
            enrollments.endCurrent(actor, id, today);
            student.deactivate(today);
        } else {
            student.activate();
        }
        audit.record(actor, status == StudentStatus.ACTIVE ? AuditAction.STUDENT_ACTIVATED
                : AuditAction.STUDENT_DEACTIVATED, ENTITY, id, Map.of("status", status == StudentStatus.ACTIVE
                ? StudentStatus.INACTIVE : StudentStatus.ACTIVE), Map.of("status", status));
        return toResponse(actor, student);
    }

    @Transactional
    public StudentResponse replaceParents(CurrentUser actor, UUID id, List<ParentLinkRequest> requested) {
        Student student = loadInScope(actor, id);
        List<StudentParentResponse> before = parentsOf(actor, id);
        links.deleteByStudentId(id);
        saveLinks(actor, id, requested);
        StudentResponse after = toResponse(actor, student);
        audit.record(actor, AuditAction.STUDENT_PARENTS_CHANGED, ENTITY, id, Map.of("parents", before),
                Map.of("parents", after.parents()));
        return after;
    }

    @Transactional(readOnly = true)
    public List<EnrollmentResponse> enrollmentHistory(CurrentUser actor, UUID id) {
        return enrollments.history(loadInScope(actor, id).getId());
    }

    @Transactional
    public EnrollmentResponse enrol(CurrentUser actor, UUID id, UUID classId, LocalDate startDate) {
        Student student = loadInScope(actor, id);
        if (!student.isActive()) {
            throw new BusinessValidationException("classId", "Reactivate the student before placing them in a class");
        }
        LocalDate today = calendar.today(actor.organisationId());
        LocalDate date = startDate == null ? today : startDate;
        if (date.isAfter(today)) {
            throw new BusinessValidationException("startDate", "The start date cannot be in the future");
        }
        if (date.isBefore(student.getJoinedOn())) {
            throw new BusinessValidationException("startDate", "The start date cannot be before the join date");
        }
        return enrollments.enrol(actor, id, classId, date);
    }

    @Transactional
    public void endEnrollment(CurrentUser actor, UUID id) {
        Student student = loadInScope(actor, id);
        enrollments.endCurrent(actor, student.getId(), calendar.today(actor.organisationId()));
    }

    private void saveLinks(CurrentUser actor, UUID studentId, List<ParentLinkRequest> requested) {
        Set<UUID> parentIds = requested.stream().map(ParentLinkRequest::parentId).collect(Collectors.toSet());
        if (parentIds.size() != requested.size()) {
            throw new BusinessValidationException("parents", "The same parent is listed twice");
        }
        long primaries = requested.stream().filter(ParentLinkRequest::isPrimary).count();
        if (primaries > 1) {
            throw new BusinessValidationException("parents", "Choose one primary contact");
        }
        if (parents.findByIdInAndOrganisationId(parentIds, actor.organisationId()).size() != parentIds.size()) {
            throw new BusinessValidationException("parents", "Parent or guardian not found");
        }
        for (int i = 0; i < requested.size(); i++) {
            ParentLinkRequest link = requested.get(i);
            // The first parent becomes the primary contact when none is chosen.
            boolean primary = link.isPrimary() || (primaries == 0 && i == 0);
            links.save(new StudentParent(studentId, link.parentId(), link.relationship(), primary));
        }
        links.flush();
    }

    private Student loadInScope(CurrentUser actor, UUID id) {
        AccessScope scope = scopes.scopeFor(actor);
        return students.findInScope(id, actor.organisationId(), scope.allClasses(), scope.queryClassIds())
                .orElseThrow(() -> new NotFoundException(ENTITY));
    }

    private StudentResponse toResponse(CurrentUser actor, Student s) {
        ClassRef currentClass = enrollments.currentClass(s.getId()).orElse(null);
        return new StudentResponse(s.getId(), s.getFirstName(), s.getLastName(), s.getDateOfBirth(), s.getGender(),
                s.getStatus(), s.getJoinedOn(), s.getLeftOn(), s.getNotes(), currentClass, parentsOf(actor, s.getId()));
    }

    /**
     * Callers with PARENT_READ see every linked parent. Others (teachers) see only the primary contact's name and
     * phone number, which is what they need to reach a family.
     */
    private List<StudentParentResponse> parentsOf(CurrentUser actor, UUID studentId) {
        boolean full = actor.has(Permission.PARENT_READ);
        List<StudentParent> studentLinks = links.findByIdStudentId(studentId).stream()
                .filter(link -> full || link.isPrimaryContact()).toList();
        if (studentLinks.isEmpty()) {
            return List.of();
        }
        Map<UUID, ParentGuardian> byId = parents.findByIdInAndOrganisationId(
                        studentLinks.stream().map(StudentParent::getParentGuardianId).toList(), actor.organisationId())
                .stream().collect(Collectors.toMap(ParentGuardian::getId, Function.identity()));
        return studentLinks.stream()
                .sorted(Comparator.comparing(StudentParent::isPrimaryContact).reversed())
                .map(link -> {
                    ParentGuardian p = byId.get(link.getParentGuardianId());
                    return new StudentParentResponse(p.getId(), p.getFirstName(), p.getLastName(), p.getPhone(),
                            full ? p.getEmail() : null, link.getRelationship(), link.isPrimaryContact());
                })
                .toList();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
