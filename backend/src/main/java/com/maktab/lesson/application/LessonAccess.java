package com.maktab.lesson.application;

import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.application.AccessScopeService;
import com.maktab.classgroup.domain.ClassEnrollment;
import com.maktab.classgroup.persistence.ClassEnrollmentRepository;
import com.maktab.common.AccessScope;
import com.maktab.common.BusinessValidationException;
import com.maktab.common.NotFoundException;
import com.maktab.lesson.domain.Lesson;
import com.maktab.lesson.persistence.LessonRepository;
import java.util.Collection;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Lets the modules that record things about a lesson (progress, behaviour, uniform) reach it the same way the
 * register does: only within the caller's classes, and only for the students in the class now.
 */
@Component
public class LessonAccess {

    private final LessonRepository lessons;
    private final ClassEnrollmentRepository enrollments;
    private final AccessScopeService scopes;

    public LessonAccess(LessonRepository lessons, ClassEnrollmentRepository enrollments, AccessScopeService scopes) {
        this.lessons = lessons;
        this.enrollments = enrollments;
        this.scopes = scopes;
    }

    /** The lesson, or 404 when it does not exist or belongs to a class the caller may not see. */
    @Transactional(readOnly = true)
    public Lesson loadInScope(CurrentUser actor, UUID lessonId) {
        AccessScope scope = scopes.scopeFor(actor);
        return lessons.findInScope(lessonId, scope.allClasses(), scope.queryClassIds())
                .orElseThrow(() -> new NotFoundException("Lesson"));
    }

    @Transactional(readOnly = true)
    public Set<UUID> roster(Lesson lesson) {
        return enrollments.findByClassGroupIdAndEndDateIsNull(lesson.getClassGroupId()).stream()
                .map(ClassEnrollment::getStudentId).collect(Collectors.toSet());
    }

    /** Rejects a student who is not in the lesson's class now, or who appears twice. */
    public void requireOnRoster(Lesson lesson, Collection<UUID> studentIds) {
        Set<UUID> roster = roster(lesson);
        Set<UUID> seen = new HashSet<>();
        for (UUID studentId : studentIds) {
            if (!roster.contains(studentId)) {
                throw new BusinessValidationException("entries", "A student in the list is not in this class");
            }
            if (!seen.add(studentId)) {
                throw new BusinessValidationException("entries", "A student appears twice in the list");
            }
        }
    }
}
