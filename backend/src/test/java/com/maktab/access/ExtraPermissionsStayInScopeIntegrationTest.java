package com.maktab.access;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.maktab.support.SchoolApi;
import com.maktab.user.domain.Role;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/**
 * A teacher can be granted extra permissions one by one. Those permissions must still only reach the teacher's own
 * classes: no grant may let them see other families or move themselves or students into another teacher's class.
 */
class ExtraPermissionsStayInScopeIntegrationTest extends SchoolApi {

    @Test
    void aTeacherWithParentAccessSeesOnlyTheFamiliesOfTheirOwnClasses() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID ownClass = createClass(admin);
        UUID otherClass = createClass(admin);
        assignTeachers(admin, ownClass, teacher.user().id());
        String family = unique("Family");
        UUID sharedParent = createParent(admin, family);
        UUID otherParent = createParent(admin, family);
        createStudent(admin, "Own", ownClass, sharedParent);
        createStudent(admin, "Sibling", otherClass, sharedParent);
        createStudent(admin, "Other", otherClass, otherParent);
        grant(admin, teacher, "PARENT_READ");

        mvc.perform(as(teacher, get("/api/parents")).param("search", family))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].id").value(sharedParent.toString()))
                // The sibling in another class stays hidden.
                .andExpect(jsonPath("$.items[0].children", hasSize(1)))
                .andExpect(jsonPath("$.items[0].children[0].firstName").value("Own"));
        mvc.perform(as(teacher, get("/api/parents/{id}", otherParent))).andExpect(status().isNotFound());

        mvc.perform(as(admin, get("/api/parents")).param("search", family))
                .andExpect(jsonPath("$.items", hasSize(2)));
    }

    @Test
    void classManagementCannotBeUsedToJoinAnotherTeachersClass() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID otherClass = createClass(admin);
        grant(admin, teacher, "CLASS_MANAGE");

        mvc.perform(as(teacher, put("/api/classes/{id}/teachers", otherClass))
                        .content("{\"teacherIds\":[\"" + teacher.user().id() + "\"]}"))
                .andExpect(status().isForbidden());
        mvc.perform(as(teacher, post("/api/classes"))
                        .content("{\"name\":\"" + unique("Class") + "\",\"curriculumLevelId\":\"" + createLevel(admin)
                                + "\",\"room\":\"Room 1\"}"))
                .andExpect(status().isForbidden());
        mvc.perform(as(teacher, get("/api/classes/{id}", otherClass))).andExpect(status().isNotFound());
    }

    @Test
    void aTeacherWhoMayEditStudentsCannotPlaceThemInAnotherTeachersClass() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID ownClass = createClass(admin);
        UUID otherClass = createClass(admin);
        assignTeachers(admin, ownClass, teacher.user().id());
        UUID studentId = createStudent(admin, "Yusuf", ownClass, null);
        grant(admin, teacher, "STUDENT_WRITE");

        mvc.perform(as(teacher, post("/api/students/{id}/enrollments", studentId))
                        .content("{\"classId\":\"" + otherClass + "\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.classId").value("Class not found"));
        mvc.perform(as(admin, get("/api/students/{id}", studentId)))
                .andExpect(jsonPath("$.currentClass.id").value(ownClass.toString()));
    }

    private void grant(Session admin, Session user, String... permissions) throws Exception {
        mvc.perform(as(admin, put("/api/users/{id}/permissions", user.user().id()))
                        .content("{\"permissions\":[\"" + String.join("\",\"", permissions) + "\"]}"))
                .andExpect(status().isOk());
    }
}
