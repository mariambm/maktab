package com.maktab.parent.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.application.AccessScopeService;
import com.maktab.classgroup.domain.ClassEnrollment;
import com.maktab.classgroup.persistence.ClassEnrollmentRepository;
import com.maktab.common.AccessScope;
import com.maktab.common.NotFoundException;
import com.maktab.common.PageResponse;
import com.maktab.common.SearchTerms;
import com.maktab.parent.api.ParentChildResponse;
import com.maktab.parent.api.ParentRequest;
import com.maktab.parent.api.ParentResponse;
import com.maktab.parent.domain.ParentGuardian;
import com.maktab.parent.persistence.ParentGuardianRepository;
import com.maktab.student.domain.Student;
import com.maktab.student.domain.StudentParent;
import com.maktab.student.persistence.StudentParentRepository;
import com.maktab.student.persistence.StudentRepository;
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
 * Parents and guardians. Only callers with PARENT_READ reach this service. Admin roles see the whole organisation; a
 * teacher who was granted PARENT_READ sees only the families of children currently in their classes, and only those
 * children.
 */
@Service
public class ParentService {

    private static final String ENTITY = "ParentGuardian";

    private final ParentGuardianRepository parents;
    private final StudentParentRepository links;
    private final StudentRepository students;
    private final ClassEnrollmentRepository enrollments;
    private final AccessScopeService scopes;
    private final AuditService audit;

    public ParentService(ParentGuardianRepository parents, StudentParentRepository links,
            StudentRepository students, ClassEnrollmentRepository enrollments, AccessScopeService scopes,
            AuditService audit) {
        this.parents = parents;
        this.links = links;
        this.students = students;
        this.enrollments = enrollments;
        this.scopes = scopes;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public PageResponse<ParentResponse> search(CurrentUser actor, String search, Pageable pageable) {
        AccessScope scope = scopes.scopeFor(actor);
        Page<ParentGuardian> page = parents.search(actor.organisationId(), SearchTerms.containsPattern(search),
                scope.allClasses(), scope.queryClassIds(), pageable);
        List<ParentResponse> items = toResponses(scope, page.getContent());
        return new PageResponse<>(items, page.getNumber(), page.getSize(), page.getTotalElements());
    }

    @Transactional(readOnly = true)
    public ParentResponse get(CurrentUser actor, UUID id) {
        return toResponses(scopes.scopeFor(actor), List.of(load(actor, id))).getFirst();
    }

    @Transactional
    public ParentResponse create(CurrentUser actor, ParentRequest request) {
        ParentGuardian parent = parents.save(new ParentGuardian(actor.organisationId(), request.firstName().trim(),
                request.lastName().trim(), request.phone().trim(), blankToNull(request.email())));
        ParentResponse response = toResponses(scopes.scopeFor(actor), List.of(parent)).getFirst();
        audit.record(actor, AuditAction.PARENT_CREATED, ENTITY, parent.getId(), null, response);
        return response;
    }

    @Transactional
    public ParentResponse update(CurrentUser actor, UUID id, ParentRequest request) {
        AccessScope scope = scopes.scopeFor(actor);
        ParentGuardian parent = load(actor, id);
        ParentResponse before = toResponses(scope, List.of(parent)).getFirst();
        parent.update(request.firstName().trim(), request.lastName().trim(), request.phone().trim(),
                blankToNull(request.email()));
        ParentResponse after = toResponses(scope, List.of(parent)).getFirst();
        audit.record(actor, AuditAction.PARENT_UPDATED, ENTITY, id, before, after);
        return after;
    }

    private ParentGuardian load(CurrentUser actor, UUID id) {
        AccessScope scope = scopes.scopeFor(actor);
        return parents.findInScope(id, actor.organisationId(), scope.allClasses(), scope.queryClassIds())
                .orElseThrow(() -> new NotFoundException("Parent or guardian"));
    }

    private List<ParentResponse> toResponses(AccessScope scope, List<ParentGuardian> page) {
        if (page.isEmpty()) {
            return List.of();
        }
        List<StudentParent> pageLinks = links.findByIdParentGuardianIdIn(
                page.stream().map(ParentGuardian::getId).toList());
        if (!scope.allClasses() && !pageLinks.isEmpty()) {
            Set<UUID> visible = enrollments.findByStudentIdInAndEndDateIsNull(
                            pageLinks.stream().map(StudentParent::getStudentId).toList()).stream()
                    .filter(e -> scope.includes(e.getClassGroupId()))
                    .map(ClassEnrollment::getStudentId)
                    .collect(Collectors.toSet());
            pageLinks = pageLinks.stream().filter(link -> visible.contains(link.getStudentId())).toList();
        }
        Map<UUID, Student> studentById = pageLinks.isEmpty() ? Map.of()
                : students.findByIdIn(pageLinks.stream().map(StudentParent::getStudentId).toList()).stream()
                        .collect(Collectors.toMap(Student::getId, Function.identity()));
        Map<UUID, List<ParentChildResponse>> children = pageLinks.stream()
                .collect(Collectors.groupingBy(StudentParent::getParentGuardianId, Collectors.mapping(link -> {
                    Student s = studentById.get(link.getStudentId());
                    return new ParentChildResponse(s.getId(), s.getFirstName(), s.getLastName(), s.getStatus(),
                            link.getRelationship(), link.isPrimaryContact());
                }, Collectors.toList())));
        return page.stream().map(p -> new ParentResponse(p.getId(), p.getFirstName(), p.getLastName(), p.getPhone(),
                p.getEmail(), children.getOrDefault(p.getId(), List.of()).stream()
                        .sorted(Comparator.comparing(ParentChildResponse::firstName)).toList()))
                .toList();
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
