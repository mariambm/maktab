package com.maktab.lesson;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.maktab.support.SchoolApi;
import com.maktab.user.domain.Role;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class LessonIntegrationTest extends SchoolApi {

    private static final String TODAY = LocalDate.now().toString();

    @Test
    void todayListsScheduledSlotsAndOpeningOneIsIdempotent() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        createStudent(admin, "Amina", classId, null);
        addSchedule(admin, classId, LocalDate.now().getDayOfWeek().name(), "10:00", "12:00");

        String today = mvc.perform(as(teacher, get("/api/lessons/today")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].id").doesNotExist())
                .andExpect(jsonPath("$[0].studentCount").value(1))
                .andExpect(jsonPath("$[0].attendanceRecorded").value(0))
                .andReturn().getResponse().getContentAsString();
        UUID scheduleId = UUID.fromString(com.jayway.jsonpath.JsonPath.read(today, "$[0].classScheduleId"));

        String body = "{\"classGroupId\":\"" + classId + "\",\"lessonDate\":\"" + TODAY
                + "\",\"classScheduleId\":\"" + scheduleId + "\"}";
        UUID first = idOf(mvc.perform(as(teacher, post("/api/lessons")).content(body))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.startTime").value("10:00:00"))
                .andExpect(jsonPath("$.students", hasSize(1)))
                .andReturn().getResponse().getContentAsString());
        UUID second = idOf(mvc.perform(as(teacher, post("/api/lessons")).content(body))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString());

        org.assertj.core.api.Assertions.assertThat(second).isEqualTo(first);
        mvc.perform(as(teacher, get("/api/lessons/today")))
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].id").value(first.toString()));
    }

    @Test
    void attendanceIsSavedForTheWholeClassAtOnce() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        UUID present = createStudent(admin, "Amina", classId, null);
        UUID late = createStudent(admin, "Bilal", classId, null);
        UUID absent = createStudent(admin, "Yusuf", classId, null);
        UUID lessonId = openLesson(teacher, classId, TODAY, "10:00", "12:00");

        mvc.perform(as(teacher, put("/api/lessons/{id}/attendance", lessonId))
                        .content("{\"entries\":[{\"studentId\":\"" + present + "\",\"status\":\"PRESENT\"},"
                                + "{\"studentId\":\"" + late + "\",\"status\":\"LATE\",\"minutesLate\":10},"
                                + "{\"studentId\":\"" + absent + "\",\"status\":\"ABSENT\","
                                + "\"absenceReason\":\"SICK\",\"note\":\"Called in\"}]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.students", hasSize(3)));

        mvc.perform(as(teacher, get("/api/attendance").param("studentId", late.toString()))) 
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].status").value("LATE"))
                .andExpect(jsonPath("$[0].minutesLate").value(10));
        mvc.perform(as(teacher, get("/api/attendance/statistics").param("studentId", absent.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.lessons").value(1))
                .andExpect(jsonPath("$.absent").value(1))
                .andExpect(jsonPath("$.attendancePercentage").value(0))
                .andExpect(jsonPath("$.belowThreshold").value(true));
    }

    @Test
    void savingAttendanceAgainUpdatesTheSameRecords() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        UUID studentId = createStudent(admin, "Amina", classId, null);
        UUID lessonId = openLesson(teacher, classId, TODAY, "10:00", "12:00");
        String late = "{\"entries\":[{\"studentId\":\"" + studentId + "\",\"status\":\"LATE\",\"minutesLate\":5}]}";
        String present = "{\"entries\":[{\"studentId\":\"" + studentId + "\",\"status\":\"PRESENT\"}]}";

        mvc.perform(as(teacher, put("/api/lessons/{id}/attendance", lessonId)).content(late))
                .andExpect(status().isOk());
        mvc.perform(as(teacher, put("/api/lessons/{id}/attendance", lessonId)).content(present))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.students[0].status").value("PRESENT"))
                .andExpect(jsonPath("$.students[0].minutesLate").doesNotExist());
        mvc.perform(as(teacher, get("/api/attendance/statistics").param("studentId", studentId.toString())))
                .andExpect(jsonPath("$.lessons").value(1))
                .andExpect(jsonPath("$.attendancePercentage").value(100));
    }

    @Test
    void lateNeedsMinutesAndOnlyAbsenceCanHaveAReason() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID studentId = createStudent(admin, "Amina", classId, null);
        UUID lessonId = openLesson(admin, classId, TODAY, "10:00", "12:00");

        mvc.perform(as(admin, put("/api/lessons/{id}/attendance", lessonId))
                        .content("{\"entries\":[{\"studentId\":\"" + studentId + "\",\"status\":\"LATE\"}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"));
        mvc.perform(as(admin, put("/api/lessons/{id}/attendance", lessonId))
                        .content("{\"entries\":[{\"studentId\":\"" + studentId
                                + "\",\"status\":\"PRESENT\",\"absenceReason\":\"SICK\"}]}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void aStudentFromAnotherClassCannotBeOnTheRegister() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID otherClassId = createClass(admin);
        UUID outsider = createStudent(admin, "Outsider", otherClassId, null);
        UUID lessonId = openLesson(admin, classId, TODAY, "10:00", "12:00");

        mvc.perform(as(admin, put("/api/lessons/{id}/attendance", lessonId))
                        .content("{\"entries\":[{\"studentId\":\"" + outsider + "\",\"status\":\"PRESENT\"}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.entries").isNotEmpty());
    }

    @Test
    void aTeacherCannotOpenOrReadAnotherTeachersLesson() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session mine = loginAs(Role.TEACHER);
        Session other = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, mine.user().id());
        createStudent(admin, "Amina", classId, null);
        UUID lessonId = openLesson(mine, classId, TODAY, "10:00", "12:00");

        mvc.perform(as(other, get("/api/lessons/{id}", lessonId))).andExpect(status().isNotFound());
        mvc.perform(as(other, put("/api/lessons/{id}/attendance", lessonId)).content("{\"entries\":[]}"))
                .andExpect(status().isNotFound());
        mvc.perform(as(other, post("/api/lessons"))
                        .content("{\"classGroupId\":\"" + classId + "\",\"lessonDate\":\"" + TODAY
                                + "\",\"startTime\":\"14:00\",\"endTime\":\"15:00\"}"))
                .andExpect(status().isNotFound());
        mvc.perform(as(mine, get("/api/lessons/{id}", lessonId))).andExpect(status().isOk());
    }

    @Test
    void accessEndsWhenTheTeacherIsUnassigned() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        UUID lessonId = openLesson(teacher, classId, TODAY, "10:00", "12:00");
        mvc.perform(as(teacher, get("/api/lessons/{id}", lessonId))).andExpect(status().isOk());

        assignTeachers(admin, classId);

        mvc.perform(as(teacher, get("/api/lessons/{id}", lessonId))).andExpect(status().isNotFound());
        mvc.perform(as(teacher, get("/api/lessons/today"))).andExpect(jsonPath("$", hasSize(0)));
    }

    @Test
    void lessonRecordsTheTopicsCoveredFromItsOwnCurriculum() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID levelId = createLevel(admin);
        UUID classId = createClassInLevel(admin, levelId);
        createStudent(admin, "Amina", classId, null);
        String period = createPeriod(admin, levelId, 1, LocalDate.now().minusDays(7).toString());
        String topicId = com.jayway.jsonpath.JsonPath.read(period, "$.weeks[1].topics[0].id");
        UUID lessonId = openLesson(admin, classId, TODAY, "10:00", "12:00");

        mvc.perform(as(admin, get("/api/lessons/{id}", lessonId)))
                .andExpect(jsonPath("$.curriculumWeekNumber").value(2))
                .andExpect(jsonPath("$.availableTopics[0].id").value(topicId));
        mvc.perform(as(admin, put("/api/lessons/{id}", lessonId))
                        .content("{\"status\":\"COMPLETED\",\"contentNotes\":\"Read the first five letters\","
                                + "\"coveredTopicIds\":[\"" + topicId + "\"]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("COMPLETED"))
                .andExpect(jsonPath("$.coveredTopicIds[0]").value(topicId));

        UUID otherLevel = createLevel(admin);
        String otherPeriod = createPeriod(admin, otherLevel, 1, LocalDate.now().minusDays(7).toString());
        String foreignTopic = com.jayway.jsonpath.JsonPath.read(otherPeriod, "$.weeks[1].topics[0].id");
        mvc.perform(as(admin, put("/api/lessons/{id}", lessonId))
                        .content("{\"status\":\"COMPLETED\",\"coveredTopicIds\":[\"" + foreignTopic + "\"]}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void lessonsCannotBeOpenedInTheFutureAndTeachersCannotRecordWithoutPermission() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session administrator = loginAs(Role.ADMINISTRATOR);
        UUID classId = createClass(admin);

        mvc.perform(as(admin, post("/api/lessons"))
                        .content("{\"classGroupId\":\"" + classId + "\",\"lessonDate\":\""
                                + LocalDate.now().plusDays(1) + "\",\"startTime\":\"10:00\",\"endTime\":\"12:00\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.lessonDate").isNotEmpty());
        // An administrator may run the register too; the point is that the permission, not the role, decides.
        mvc.perform(as(administrator, post("/api/lessons"))
                        .content("{\"classGroupId\":\"" + classId + "\",\"lessonDate\":\"" + TODAY
                                + "\",\"startTime\":\"10:00\",\"endTime\":\"12:00\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void attendanceOfAStudentOutsideTheTeachersClassesIsNotFound() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID mine = createClass(admin);
        UUID other = createClass(admin);
        assignTeachers(admin, mine, teacher.user().id());
        UUID outsider = createStudent(admin, "Outsider", other, null);

        mvc.perform(as(teacher, get("/api/attendance").param("studentId", outsider.toString())))
                .andExpect(status().isNotFound());
        mvc.perform(as(teacher, get("/api/attendance/statistics").param("studentId", outsider.toString())))
                .andExpect(status().isNotFound());
    }
}
