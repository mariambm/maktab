package com.maktab.classgroup.application;

import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.persistence.ClassTeacherRepository;
import com.maktab.common.AccessScope;
import com.maktab.user.domain.Role;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Resolves which classes a caller may see. Admin roles see everything; anyone else (teachers) sees only the classes
 * they are assigned to right now, so access ends the moment an assignment ends.
 */
@Service
public class AccessScopeService {

    private final ClassTeacherRepository classTeachers;

    public AccessScopeService(ClassTeacherRepository classTeachers) {
        this.classTeachers = classTeachers;
    }

    @Transactional(readOnly = true)
    public AccessScope scopeFor(CurrentUser user) {
        if (user.hasRole(Role.ADMIN) || user.hasRole(Role.ADMINISTRATOR)) {
            return AccessScope.everything();
        }
        return AccessScope.classes(classTeachers.findCurrentClassIds(user.id()));
    }
}
