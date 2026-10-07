package com.maktab.student.application;

import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.application.AccessScopeService;
import com.maktab.common.AccessScope;
import com.maktab.common.NotFoundException;
import com.maktab.student.persistence.StudentRepository;
import java.util.UUID;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Checks that the caller may see a student before another module returns anything about them. */
@Component
public class StudentAccess {

    private final StudentRepository students;
    private final AccessScopeService scopes;

    public StudentAccess(StudentRepository students, AccessScopeService scopes) {
        this.students = students;
        this.scopes = scopes;
    }

    /** 404 when the student does not exist or is outside the caller's classes. */
    @Transactional(readOnly = true)
    public void requireInScope(CurrentUser actor, UUID studentId) {
        AccessScope scope = scopes.scopeFor(actor);
        students.findInScope(studentId, actor.organisationId(), scope.allClasses(), scope.queryClassIds())
                .orElseThrow(() -> new NotFoundException("Student"));
    }
}
