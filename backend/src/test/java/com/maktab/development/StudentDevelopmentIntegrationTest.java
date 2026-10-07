package com.maktab.development;

import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.maktab.support.SchoolApi;
import com.maktab.user.domain.Role;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Progress, behaviour and uniform: recorded per lesson, read back per student, and only within the caller's classes. */
class StudentDevelopmentIntegrationTest extends SchoolApi {

    private static final String TODAY = LocalDate.now().toString();
    private static final String LAST_WEEK = LocalDate.now().minusDays(7).toString();

    @Test
    void theProgressScaleIsTheMosquesOwn() throws Exception {
        Session teacher = loginAs(Role.TEACHER);

        mvc.perform(as(teacher, get("/api/progress/scale")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[*].score", contains(2.0, 3.0, 3.5, 4.0, 4.5, 5.0)))
                .andExpect(jsonPath("$[*].label",
                        contains("Low", "Medium", "Almost Good", "Good", "Very Good", "Excellent")));
    }

    @Test
    void progressIsScoredPerSubjectAndOnlyOnTheScale() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        UUID amina = createStudent(admin, "Amina", classId, null);
        UUID bilal = createStudent(admin, "Bilal", classId, null);
        UUID lessonId = openLesson(teacher, classId, TODAY, "10:00", "12:00");

        mvc.perform(as(teacher, put("/api/lessons/{id}/progress", lessonId))
                        .content("{\"subject\":\"QURAN_RECITATION\",\"entries\":["
                                + "{\"studentId\":\"" + amina + "\",\"score\":3.5,\"note\":\"  Needs makharij  \"},"
                                + "{\"studentId\":\"" + bilal + "\",\"score\":5}]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.scores", hasSize(2)));
        mvc.perform(as(teacher, put("/api/lessons/{id}/progress", lessonId))
                        .content("{\"subject\":\"ARABIC\",\"entries\":[{\"studentId\":\"" + amina
                                + "\",\"score\":4}]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.scores", hasSize(3)));

        // Saving Quran again without Bilal removes only his Quran score; Arabic is untouched.
        mvc.perform(as(teacher, put("/api/lessons/{id}/progress", lessonId))
                        .content("{\"subject\":\"QURAN_RECITATION\",\"entries\":[{\"studentId\":\"" + amina
                                + "\",\"score\":4.5}]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.scores", hasSize(2)));

        mvc.perform(as(teacher, get("/api/progress").param("studentId", amina.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[?(@.subject == 'QURAN_RECITATION')].label").value("Very Good"))
                .andExpect(jsonPath("$[?(@.subject == 'ARABIC')].lessonDate").value(TODAY));
        mvc.perform(as(teacher, get("/api/progress").param("studentId", bilal.toString())))
                .andExpect(jsonPath("$", hasSize(0)));

        for (String score : new String[] {"1", "2.5", "6"}) {
            mvc.perform(as(teacher, put("/api/lessons/{id}/progress", lessonId))
                            .content("{\"subject\":\"ARABIC\",\"entries\":[{\"studentId\":\"" + amina
                                    + "\",\"score\":" + score + "}]}"))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.fieldErrors.entries").isNotEmpty());
        }
    }

    @Test
    void behaviourIsSeveralObservationsPerLessonAndEachLessonKeepsItsOwnDate() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        UUID amina = createStudent(admin, "Amina", classId, null);
        UUID earlier = openLesson(teacher, classId, LAST_WEEK, "10:00", "12:00");
        UUID today = openLesson(teacher, classId, TODAY, "10:00", "12:00");

        mvc.perform(as(teacher, put("/api/lessons/{id}/behaviour", earlier))
                        .content("{\"entries\":[{\"studentId\":\"" + amina
                                + "\",\"behaviours\":[\"TALKING\",\"OFF_TASK\"]}]}"))
                .andExpect(status().isOk());
        mvc.perform(as(teacher, put("/api/lessons/{id}/behaviour", today))
                        .content("{\"entries\":[{\"studentId\":\"" + amina + "\",\"behaviours\":"
                                + "[\"RESPECTFUL\",\"GOOD_QURAN_RECITATION\"],\"note\":\"Helped a new student\"}]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.observations[0].behaviours",
                        contains("GOOD_QURAN_RECITATION", "RESPECTFUL")));

        mvc.perform(as(teacher, get("/api/behaviour").param("studentId", amina.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].lessonDate").value(TODAY))
                .andExpect(jsonPath("$[0].note").value("Helped a new student"))
                .andExpect(jsonPath("$[1].lessonDate").value(LAST_WEEK))
                .andExpect(jsonPath("$[1].behaviours", contains("OFF_TASK", "TALKING")));

        // Clearing every choice removes that lesson's observation, and only that one.
        mvc.perform(as(teacher, put("/api/lessons/{id}/behaviour", earlier))
                        .content("{\"entries\":[{\"studentId\":\"" + amina + "\",\"behaviours\":[]}]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.observations", hasSize(0)));
        mvc.perform(as(teacher, get("/api/behaviour").param("studentId", amina.toString())))
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].lessonDate").value(TODAY));

        mvc.perform(as(teacher, put("/api/lessons/{id}/behaviour", today))
                        .content("{\"entries\":[{\"studentId\":\"" + amina + "\",\"behaviours\":[\"LAZY\"]}]}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void uniformInOrderHasNoReason() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID amina = createStudent(admin, "Amina", classId, null);
        UUID bilal = createStudent(admin, "Bilal", classId, null);
        UUID lessonId = openLesson(admin, classId, TODAY, "10:00", "12:00");

        mvc.perform(as(admin, put("/api/lessons/{id}/uniform", lessonId))
                        .content("{\"entries\":[{\"studentId\":\"" + amina
                                + "\",\"status\":\"IN_ORDER\",\"reason\":\"HIJAB_MISSING\"}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"));
        mvc.perform(as(admin, put("/api/lessons/{id}/uniform", lessonId))
                        .content("{\"entries\":[{\"studentId\":\"" + amina
                                + "\",\"status\":\"PARTIALLY_IN_ORDER\",\"reason\":\"HIJAB_MISSING\"},"
                                + "{\"studentId\":\"" + bilal + "\",\"status\":\"NOT_IN_ORDER\"}]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.records", hasSize(2)));

        mvc.perform(as(admin, get("/api/uniform").param("studentId", amina.toString())))
                .andExpect(jsonPath("$[0].status").value("PARTIALLY_IN_ORDER"))
                .andExpect(jsonPath("$[0].reason").value("HIJAB_MISSING"))
                .andExpect(jsonPath("$[0].lessonDate").value(TODAY));
    }

    @Test
    void onlyStudentsInTheClassCanBeRecorded() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID outsider = createStudent(admin, "Outsider", createClass(admin), null);
        UUID lessonId = openLesson(admin, classId, TODAY, "10:00", "12:00");

        mvc.perform(as(admin, put("/api/lessons/{id}/progress", lessonId))
                        .content("{\"subject\":\"ARABIC\",\"entries\":[{\"studentId\":\"" + outsider
                                + "\",\"score\":4}]}"))
                .andExpect(status().isBadRequest());
        mvc.perform(as(admin, put("/api/lessons/{id}/behaviour", lessonId))
                        .content("{\"entries\":[{\"studentId\":\"" + outsider + "\",\"behaviours\":[\"TALKING\"]}]}"))
                .andExpect(status().isBadRequest());
        mvc.perform(as(admin, put("/api/lessons/{id}/uniform", lessonId))
                        .content("{\"entries\":[{\"studentId\":\"" + outsider + "\",\"status\":\"IN_ORDER\"}]}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void aTeacherCannotReachAnotherTeachersLessonOrStudentByItsId() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session mine = loginAs(Role.TEACHER);
        Session other = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, mine.user().id());
        UUID amina = createStudent(admin, "Amina", classId, null);
        UUID lessonId = openLesson(mine, classId, TODAY, "10:00", "12:00");

        for (String path : new String[] {"progress", "behaviour", "uniform"}) {
            mvc.perform(as(other, get("/api/lessons/{id}/" + path, lessonId))).andExpect(status().isNotFound());
            mvc.perform(as(other, get("/api/" + path).param("studentId", amina.toString())))
                    .andExpect(status().isNotFound());
            mvc.perform(as(mine, get("/api/lessons/{id}/" + path, lessonId))).andExpect(status().isOk());
        }
        mvc.perform(as(other, put("/api/lessons/{id}/progress", lessonId))
                        .content("{\"subject\":\"ARABIC\",\"entries\":[]}"))
                .andExpect(status().isNotFound());
        mvc.perform(as(other, put("/api/lessons/{id}/behaviour", lessonId)).content("{\"entries\":[]}"))
                .andExpect(status().isNotFound());
        mvc.perform(as(other, put("/api/lessons/{id}/uniform", lessonId)).content("{\"entries\":[]}"))
                .andExpect(status().isNotFound());
    }
}
