package com.maktab.student;

import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.maktab.support.SchoolApi;
import com.maktab.user.domain.Role;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class StudentIntegrationTest extends SchoolApi {

    @Test
    void administratorCreatesAStudentWithClassAndParentInOneRequest() throws Exception {
        Session administrator = loginAs(Role.ADMINISTRATOR);
        UUID classId = createClass(administrator);
        UUID parentId = createParent(administrator, "Amrani");

        UUID studentId = createStudent(administrator, "Amina", classId, parentId);

        mvc.perform(as(administrator, get("/api/students/{id}", studentId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Amina"))
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.currentClass.id").value(classId.toString()))
                .andExpect(jsonPath("$.parents[0].parentId").value(parentId.toString()))
                .andExpect(jsonPath("$.parents[0].primaryContact").value(true))
                .andExpect(jsonPath("$.parents[0].email").value("parent@example.com"));
    }

    @Test
    void parentCanHaveMultipleChildren() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID parentId = createParent(admin, "Bakkali");
        createStudent(admin, "Sara", classId, parentId);
        createStudent(admin, "Adam", null, parentId);

        mvc.perform(as(admin, get("/api/parents/{id}", parentId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.children", hasSize(2)))
                .andExpect(jsonPath("$.children[0].firstName").value("Adam"))
                .andExpect(jsonPath("$.children[1].firstName").value("Sara"));
    }

    @Test
    void studentClassHistoryIsPreservedWhenMovingClass() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID firstClass = createClass(admin);
        UUID secondClass = createClass(admin);
        UUID studentId = createStudent(admin, "Noor", firstClass, null);

        mvc.perform(as(admin, post("/api/students/{id}/enrollments", studentId))
                        .content("{\"classId\":\"" + secondClass + "\",\"startDate\":\"2026-10-01\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.classGroup.id").value(secondClass.toString()))
                .andExpect(jsonPath("$.endDate").value(nullValue()));

        mvc.perform(as(admin, get("/api/students/{id}/enrollments", studentId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].classGroup.id").value(secondClass.toString()))
                .andExpect(jsonPath("$[0].startDate").value("2026-10-01"))
                .andExpect(jsonPath("$[1].classGroup.id").value(firstClass.toString()))
                .andExpect(jsonPath("$[1].startDate").value("2026-09-01"))
                .andExpect(jsonPath("$[1].endDate").value("2026-10-01"));

        mvc.perform(as(admin, get("/api/classes/{id}/students", firstClass)))
                .andExpect(jsonPath("$", hasSize(0)));
        mvc.perform(as(admin, get("/api/classes/{id}/students", secondClass)))
                .andExpect(jsonPath("$[0].id").value(studentId.toString()));
    }

    @Test
    void movingToTheSameClassOrBeforeTheCurrentStartIsRejected() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID firstClass = createClass(admin);
        UUID secondClass = createClass(admin);
        UUID studentId = createStudent(admin, "Huda", firstClass, null);

        mvc.perform(as(admin, post("/api/students/{id}/enrollments", studentId))
                        .content("{\"classId\":\"" + firstClass + "\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.classId").value("The student is already in this class"));
        mvc.perform(as(admin, post("/api/students/{id}/enrollments", studentId))
                        .content("{\"classId\":\"" + secondClass + "\",\"startDate\":\"2026-08-01\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"));
    }

    @Test
    void teacherCannotReadStudentsOutsideTheirClassesByChangingTheId() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID myClass = createClass(admin);
        UUID otherClass = createClass(admin);
        assignTeachers(admin, myClass, teacher.user().id());
        UUID mine = createStudent(admin, "Maryam", myClass, null);
        UUID notMine = createStudent(admin, "Ilyas", otherClass, null);

        mvc.perform(as(teacher, get("/api/students/{id}", mine))).andExpect(status().isOk());
        mvc.perform(as(teacher, get("/api/students/{id}", notMine)))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("NOT_FOUND"));
        mvc.perform(as(teacher, get("/api/students/{id}/enrollments", notMine)))
                .andExpect(status().isNotFound());
        mvc.perform(as(teacher, get("/api/classes/{id}", otherClass))).andExpect(status().isNotFound());
        mvc.perform(as(teacher, get("/api/classes/{id}/students", otherClass))).andExpect(status().isNotFound());

        mvc.perform(as(teacher, get("/api/students").param("size", "100")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[*].id", hasItem(mine.toString())))
                .andExpect(jsonPath("$.items[*].id", not(hasItem(notMine.toString()))));
        mvc.perform(as(teacher, get("/api/students").param("classId", otherClass.toString())))
                .andExpect(jsonPath("$.totalItems").value(0));
    }

    @Test
    void teacherLosesAccessWhenTheirAssignmentEnds() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        UUID studentId = createStudent(admin, "Layla", classId, null);
        mvc.perform(as(teacher, get("/api/students/{id}", studentId))).andExpect(status().isOk());

        assignTeachers(admin, classId);

        mvc.perform(as(teacher, get("/api/students/{id}", studentId))).andExpect(status().isNotFound());
        mvc.perform(as(teacher, get("/api/classes"))).andExpect(jsonPath("$.totalItems").value(0));
    }

    @Test
    void adminAndAdministratorCanAccessAllStudents() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID unassignedClass = createClass(admin);
        UUID studentId = createStudent(admin, "Safiya", unassignedClass, null);
        UUID withoutClass = createStudent(admin, "Asma", null, null);

        for (Session session : new Session[] {admin, loginAs(Role.ADMINISTRATOR)}) {
            mvc.perform(as(session, get("/api/students/{id}", studentId))).andExpect(status().isOk());
            mvc.perform(as(session, get("/api/students/{id}", withoutClass)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.currentClass").value(nullValue()));
        }
    }

    @Test
    void teacherSeesOnlyThePrimaryContactsNameAndPhone() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        UUID mother = createParent(admin, "Celik");
        UUID father = createParent(admin, "Celik");
        UUID studentId = createStudent(admin, "Iman", classId, null);
        mvc.perform(as(admin, put("/api/students/{id}/parents", studentId))
                        .content("{\"parents\":[{\"parentId\":\"" + mother + "\",\"relationship\":\"MOTHER\","
                                + "\"primaryContact\":true},{\"parentId\":\"" + father + "\","
                                + "\"relationship\":\"FATHER\",\"primaryContact\":false}]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.parents", hasSize(2)));

        mvc.perform(as(teacher, get("/api/students/{id}", studentId)))
                .andExpect(jsonPath("$.parents", hasSize(1)))
                .andExpect(jsonPath("$.parents[0].parentId").value(mother.toString()))
                .andExpect(jsonPath("$.parents[0].phone").value("+31 6 1234 5678"))
                .andExpect(jsonPath("$.parents[0].email").value(nullValue()));
    }

    @Test
    void teachersCannotChangeStudentsOrSeeParents() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        UUID studentId = createStudent(admin, "Aya", classId, null);

        String student = "{\"firstName\":\"Aya\",\"lastName\":\"Test\",\"dateOfBirth\":\"2017-01-01\","
                + "\"joinedOn\":\"2026-09-01\"}";
        mvc.perform(as(teacher, post("/api/students")).content(student)).andExpect(status().isForbidden());
        mvc.perform(as(teacher, put("/api/students/{id}", studentId)).content(student))
                .andExpect(status().isForbidden());
        mvc.perform(as(teacher, patch("/api/students/{id}/status", studentId)).content("{\"status\":\"INACTIVE\"}"))
                .andExpect(status().isForbidden());
        mvc.perform(as(teacher, get("/api/parents"))).andExpect(status().isForbidden());
        mvc.perform(as(teacher, post("/api/classes"))
                        .content("{\"name\":\"X\",\"curriculumLevelId\":\"" + UUID.randomUUID() + "\"}"))
                .andExpect(status().isForbidden());
        mvc.perform(as(teacher, get("/api/teachers"))).andExpect(status().isForbidden());
    }

    @Test
    void deactivatingAStudentEndsTheirClassButKeepsHistory() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID studentId = createStudent(admin, "Sumaya", classId, null);

        mvc.perform(as(admin, patch("/api/students/{id}/status", studentId)).content("{\"status\":\"INACTIVE\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("INACTIVE"))
                .andExpect(jsonPath("$.leftOn").isNotEmpty())
                .andExpect(jsonPath("$.currentClass").value(nullValue()));
        mvc.perform(as(admin, get("/api/students/{id}/enrollments", studentId)))
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].endDate").isNotEmpty());
        mvc.perform(as(admin, post("/api/students/{id}/enrollments", studentId))
                        .content("{\"classId\":\"" + classId + "\"}"))
                .andExpect(status().isBadRequest());

        mvc.perform(as(admin, patch("/api/students/{id}/status", studentId)).content("{\"status\":\"ACTIVE\"}"))
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.leftOn").value(nullValue()));
    }

    @Test
    void removingAStudentFromTheirClassKeepsTheStudent() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID studentId = createStudent(admin, "Hiba", classId, null);

        mvc.perform(as(admin, delete("/api/students/{id}/enrollments/current", studentId)))
                .andExpect(status().isNoContent());
        mvc.perform(as(admin, get("/api/students/{id}", studentId)))
                .andExpect(jsonPath("$.status").value("ACTIVE"))
                .andExpect(jsonPath("$.currentClass").value(nullValue()));
    }

    @Test
    void invalidStudentsAreRejectedWithFieldErrors() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        mvc.perform(as(admin, post("/api/students"))
                        .content("{\"firstName\":\"\",\"lastName\":\"Test\",\"dateOfBirth\":\"2999-01-01\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fieldErrors.firstName").value("First name is required"))
                .andExpect(jsonPath("$.fieldErrors.dateOfBirth").value("Date of birth must be in the past"));

        UUID parentId = createParent(admin, "Demir");
        mvc.perform(as(admin, post("/api/students"))
                        .content("{\"firstName\":\"A\",\"lastName\":\"B\",\"dateOfBirth\":\"2017-01-01\","
                                + "\"parents\":[{\"parentId\":\"" + parentId + "\",\"relationship\":\"MOTHER\"},"
                                + "{\"parentId\":\"" + parentId + "\",\"relationship\":\"FATHER\"}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.parents").value("The same parent is listed twice"));
    }

    @Test
    void searchFindsStudentsByPartOfTheirFullName() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        String name = "Zx" + UUID.randomUUID().toString().substring(0, 6);
        UUID studentId = createStudent(admin, name, null, null);

        mvc.perform(as(admin, get("/api/students").param("search", name.toUpperCase() + " tes")))
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].id").value(studentId.toString()));
        mvc.perform(as(admin, get("/api/students").param("search", "%")))
                .andExpect(status().isOk());
    }

    @Test
    void studentChangesAreAudited() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID studentId = createStudent(admin, "Ruqayya", null, null);

        mvc.perform(as(admin, get("/api/audit-log").param("entityId", studentId.toString())))
                .andExpect(jsonPath("$.items[0].action").value("STUDENT_CREATED"))
                .andExpect(jsonPath("$.items[0].entityType").value("Student"));
    }
}
