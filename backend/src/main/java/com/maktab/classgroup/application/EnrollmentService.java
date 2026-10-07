package com.maktab.classgroup.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.api.ClassRef;
import com.maktab.classgroup.api.EnrollmentResponse;
import com.maktab.classgroup.domain.ClassEnrollment;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.persistence.ClassEnrollmentRepository;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.common.BusinessValidationException;
import java.time.LocalDate;
import java.util.Collection;
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
 * Class membership over time. Callers (the student service) check that the student exists and is in scope first;
 * this service owns the rules about classes and dates.
 */
@Service
public class EnrollmentService {

    private static final String ENTITY = "ClassEnrollment";

    private final ClassEnrollmentRepository enrollments;
    private final ClassGroupRepository classes;
    private final AuditService audit;

    public EnrollmentService(ClassEnrollmentRepository enrollments, ClassGroupRepository classes,
            AuditService audit) {
        this.enrollments = enrollments;
        this.classes = classes;
        this.audit = audit;
    }

    /** The current class of each given student; students without a class are absent from the map. */
    @Transactional(readOnly = true)
    public Map<UUID, ClassRef> currentClasses(Collection<UUID> studentIds) {
        if (studentIds.isEmpty()) {
            return Map.of();
        }
        List<ClassEnrollment> open = enrollments.findByStudentIdInAndEndDateIsNull(studentIds);
        Map<UUID, ClassGroup> byId = classesById(open.stream().map(ClassEnrollment::getClassGroupId)
                .collect(Collectors.toSet()));
        return open.stream().collect(Collectors.toMap(ClassEnrollment::getStudentId,
                e -> toRef(byId.get(e.getClassGroupId()))));
    }

    @Transactional(readOnly = true)
    public Optional<ClassRef> currentClass(UUID studentId) {
        return Optional.ofNullable(currentClasses(List.of(studentId)).get(studentId));
    }

    @Transactional(readOnly = true)
    public List<EnrollmentResponse> history(UUID studentId) {
        List<ClassEnrollment> rows = enrollments.findHistory(studentId);
        Map<UUID, ClassGroup> byId = classesById(rows.stream().map(ClassEnrollment::getClassGroupId)
                .collect(Collectors.toSet()));
        return rows.stream().map(e -> toResponse(e, byId.get(e.getClassGroupId()))).toList();
    }

    /**
     * Puts the student in {@code classId} from {@code startDate}, closing their current enrolment on that date.
     * The class must be active and different from the current one.
     */
    @Transactional
    public EnrollmentResponse enrol(CurrentUser actor, UUID studentId, UUID classId, LocalDate startDate) {
        ClassGroup target = classes.findByIdAndOrganisationId(classId, actor.organisationId())
                .orElseThrow(() -> new BusinessValidationException("classId", "Class not found"));
        if (!target.isActive()) {
            throw new BusinessValidationException("classId", "This class is inactive");
        }
        Optional<ClassEnrollment> current = enrollments.findByStudentIdAndEndDateIsNull(studentId);
        if (current.isPresent()) {
            ClassEnrollment open = current.get();
            if (open.getClassGroupId().equals(classId)) {
                throw new BusinessValidationException("classId", "The student is already in this class");
            }
            if (startDate.isBefore(open.getStartDate())) {
                throw new BusinessValidationException("startDate",
                        "The move cannot be before the current class started (" + open.getStartDate() + ")");
            }
            open.end(startDate);
            enrollments.saveAndFlush(open);
            audit.record(actor, AuditAction.ENROLLMENT_ENDED, ENTITY, open.getId(), null,
                    Map.of("studentId", studentId, "classId", open.getClassGroupId(), "endDate", startDate));
        }
        ClassEnrollment enrollment = enrollments.save(new ClassEnrollment(studentId, classId, startDate));
        EnrollmentResponse response = toResponse(enrollment, target);
        audit.record(actor, AuditAction.ENROLLMENT_STARTED, ENTITY, enrollment.getId(), null,
                Map.of("studentId", studentId, "classId", classId, "startDate", startDate));
        return response;
    }

    /** Ends the student's current enrolment, if any, on {@code endDate}. */
    @Transactional
    public void endCurrent(CurrentUser actor, UUID studentId, LocalDate endDate) {
        enrollments.findByStudentIdAndEndDateIsNull(studentId).ifPresent(open -> {
            open.end(endDate.isBefore(open.getStartDate()) ? open.getStartDate() : endDate);
            audit.record(actor, AuditAction.ENROLLMENT_ENDED, ENTITY, open.getId(), null,
                    Map.of("studentId", studentId, "classId", open.getClassGroupId(), "endDate", open.getEndDate()));
        });
    }

    private Map<UUID, ClassGroup> classesById(Set<UUID> ids) {
        return ids.isEmpty() ? Map.of()
                : classes.findByIdIn(ids).stream().collect(Collectors.toMap(ClassGroup::getId, Function.identity()));
    }

    private static EnrollmentResponse toResponse(ClassEnrollment enrollment, ClassGroup classGroup) {
        return new EnrollmentResponse(enrollment.getId(), toRef(classGroup), enrollment.getStartDate(),
                enrollment.getEndDate());
    }

    private static ClassRef toRef(ClassGroup classGroup) {
        return new ClassRef(classGroup.getId(), classGroup.getName());
    }
}
