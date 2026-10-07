package com.maktab.classgroup;

import static org.hamcrest.Matchers.hasItem;
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

class ClassIntegrationTest extends SchoolApi {

    @Test
    void classShowsLevelTeachersScheduleAndStudentCount() throws Exception {
        Session administrator = loginAs(Role.ADMINISTRATOR);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(administrator);
        assignTeachers(administrator, classId, teacher.user().id());
        mvc.perform(as(administrator, put("/api/classes/{id}/schedule", classId))
                        .content("{\"slots\":[{\"weekday\":\"SATURDAY\",\"startTime\":\"10:00\","
                                + "\"endTime\":\"12:00\"}]}"))
                .andExpect(status().isOk());
        createStudent(administrator, "Musa", classId, null);

        mvc.perform(as(administrator, get("/api/classes/{id}", classId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.curriculumLevel.name").isNotEmpty())
                .andExpect(jsonPath("$.studentCount").value(1))
                .andExpect(jsonPath("$.teachers[0].id").value(teacher.user().id().toString()))
                .andExpect(jsonPath("$.schedule[0].weekday").value("SATURDAY"))
                .andExpect(jsonPath("$.schedule[0].startTime").value("10:00:00"))
                .andExpect(jsonPath("$.schedule[0].endAfterStart").doesNotExist());
    }

    @Test
    void teacherSeesOnlyTheirOwnClasses() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID mine = createClass(admin);
        createClass(admin);
        assignTeachers(admin, mine, teacher.user().id());

        mvc.perform(as(teacher, get("/api/classes")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].id").value(mine.toString()));
        mvc.perform(as(admin, get("/api/classes").param("size", "100")))
                .andExpect(jsonPath("$.items[*].id", hasItem(mine.toString())));
    }

    @Test
    void onlyActiveTeachersCanBeAssigned() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID administratorId = testUsers.create(Role.ADMINISTRATOR).id();

        mvc.perform(as(admin, put("/api/classes/{id}/teachers", classId))
                        .content("{\"teacherIds\":[\"" + administratorId + "\"]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.teacherIds").value("Choose active teachers only"));
        mvc.perform(as(admin, put("/api/classes/{id}/teachers", classId))
                        .content("{\"teacherIds\":[\"" + UUID.randomUUID() + "\"]}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void scheduleSlotsMustEndAfterTheyStart() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);

        mvc.perform(as(admin, put("/api/classes/{id}/schedule", classId))
                        .content("{\"slots\":[{\"weekday\":\"MONDAY\",\"startTime\":\"12:00\","
                                + "\"endTime\":\"10:00\"}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"));
    }

    @Test
    void aClassWithStudentsCannotBeDeactivated() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID levelId = createLevel(admin);
        String name = unique("Class");
        UUID classId = idOf(mvc.perform(as(admin, post("/api/classes"))
                        .content("{\"name\":\"" + name + "\",\"curriculumLevelId\":\"" + levelId + "\"}"))
                .andReturn().getResponse().getContentAsString());
        createStudent(admin, "Yahya", classId, null);

        mvc.perform(as(admin, put("/api/classes/{id}", classId))
                        .content("{\"name\":\"" + name + "\",\"curriculumLevelId\":\"" + levelId
                                + "\",\"active\":false}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.active")
                        .value("Move the 1 student(s) in this class to another class first"));
    }

    @Test
    void classNamesAreUnique() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID levelId = createLevel(admin);
        String body = "{\"name\":\"" + unique("Class") + "\",\"curriculumLevelId\":\"" + levelId + "\"}";
        mvc.perform(as(admin, post("/api/classes")).content(body)).andExpect(status().isCreated());
        mvc.perform(as(admin, post("/api/classes")).content(body))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("CONFLICT"));
    }

    @Test
    void administratorsCanListTeachersToAssign() throws Exception {
        Session administrator = loginAs(Role.ADMINISTRATOR);
        UUID teacherId = testUsers.create(Role.TEACHER).id();

        mvc.perform(as(administrator, get("/api/teachers")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].id", hasItem(teacherId.toString())));
    }
}
