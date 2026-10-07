package com.maktab.development;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.maktab.support.SchoolApi;
import com.maktab.user.domain.Role;
import java.time.LocalDate;
import java.util.UUID;
import org.junit.jupiter.api.Test;

/** Targets belong to a student and a four-week period of their level, and stay available once that period is over. */
class TargetIntegrationTest extends SchoolApi {

    private static final String TODAY = LocalDate.now().toString();

    private static String target(UUID studentId, String periodId, String extra) {
        return "{\"studentId\":\"" + studentId + "\",\"curriculumPeriodId\":\"" + periodId
                + "\",\"subject\":\"QURAN_RECITATION\",\"description\":\"Recite Surah Al-Fatiha from memory\""
                + extra + "}";
    }

    @Test
    void aTargetBelongsToAPeriodAndKeepsItsHistory() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID levelId = createLevel(admin);
        UUID classId = createClassInLevel(admin, levelId);
        assignTeachers(admin, classId, teacher.user().id());
        UUID amina = createStudent(admin, "Amina", classId, null);
        String previous = JsonPath.read(createPeriod(admin, levelId, 1,
                LocalDate.now().minusDays(35).toString()), "$.id");
        String current = JsonPath.read(createPeriod(admin, levelId, 2,
                LocalDate.now().minusDays(7).toString()), "$.id");

        mvc.perform(as(teacher, post("/api/targets")).content(target(amina, previous,
                        ",\"targetPercentage\":85,\"currentPercentage\":80,\"progressScore\":4,"
                                + "\"teacherNote\":\"Good progress. Needs more practice with madd.\"")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.period.number").value(1))
                .andExpect(jsonPath("$.progressLabel").value("Good"));
        String created = mvc.perform(as(teacher, post("/api/targets")).content(target(amina, current, "")))
                .andExpect(status().isCreated())
                .andReturn().getResponse().getContentAsString();

        mvc.perform(as(teacher, put("/api/targets/{id}", idOf(created)))
                        .content("{\"description\":\"Recite Surah Al-Fatiha from memory\",\"currentPercentage\":60,"
                                + "\"progressScore\":3.5}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentPercentage").value(60))
                .andExpect(jsonPath("$.progressLabel").value("Almost Good"))
                .andExpect(jsonPath("$.subject").doesNotExist());

        mvc.perform(as(teacher, get("/api/targets").param("studentId", amina.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)))
                .andExpect(jsonPath("$[0].period.number").value(2))
                .andExpect(jsonPath("$[1].period.number").value(1))
                .andExpect(jsonPath("$[1].targetPercentage").value(85))
                .andExpect(jsonPath("$[1].teacherNote").value("Good progress. Needs more practice with madd."));
    }

    @Test
    void aTargetMustUseAPeriodOfTheStudentsLevelAndTheScale() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID levelId = createLevel(admin);
        UUID amina = createStudent(admin, "Amina", createClassInLevel(admin, levelId), null);
        String period = JsonPath.read(createPeriod(admin, levelId, 1, TODAY), "$.id");
        String otherLevelsPeriod = JsonPath.read(createPeriod(admin, createLevel(admin), 1, TODAY), "$.id");

        mvc.perform(as(admin, post("/api/targets")).content(target(amina, otherLevelsPeriod, "")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.curriculumPeriodId").isNotEmpty());
        mvc.perform(as(admin, post("/api/targets")).content(target(amina, period, ",\"progressScore\":2.5")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.progressScore").isNotEmpty());
        mvc.perform(as(admin, post("/api/targets")).content(target(amina, period, ",\"targetPercentage\":120")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.targetPercentage").isNotEmpty());
        mvc.perform(as(admin, post("/api/targets"))
                        .content("{\"studentId\":\"" + amina + "\",\"curriculumPeriodId\":\"" + period
                                + "\",\"description\":\" \"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.description").isNotEmpty());
    }

    @Test
    void anotherTeacherCannotReadOrChangeATargetByItsId() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session mine = loginAs(Role.TEACHER);
        Session other = loginAs(Role.TEACHER);
        UUID levelId = createLevel(admin);
        UUID classId = createClassInLevel(admin, levelId);
        assignTeachers(admin, classId, mine.user().id());
        UUID amina = createStudent(admin, "Amina", classId, null);
        String period = JsonPath.read(createPeriod(admin, levelId, 1, TODAY), "$.id");
        UUID targetId = idOf(mvc.perform(as(mine, post("/api/targets")).content(target(amina, period, "")))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString());

        mvc.perform(as(other, get("/api/targets").param("studentId", amina.toString())))
                .andExpect(status().isNotFound());
        mvc.perform(as(other, put("/api/targets/{id}", targetId)).content("{\"description\":\"Changed\"}"))
                .andExpect(status().isNotFound());
        mvc.perform(as(other, post("/api/targets")).content(target(amina, period, "")))
                .andExpect(status().isNotFound());
        mvc.perform(as(other, get("/api/progress/classes/{id}", classId))).andExpect(status().isNotFound());
    }

    @Test
    void theClassOverviewShowsEachStudentsLatestScoreAndTargetsForThePeriodNow() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID levelId = createLevel(admin);
        UUID classId = createClassInLevel(admin, levelId);
        assignTeachers(admin, classId, teacher.user().id());
        UUID amina = createStudent(admin, "Amina", classId, null);
        createStudent(admin, "Bilal", classId, null);
        String period = JsonPath.read(createPeriod(admin, levelId, 1, LocalDate.now().minusDays(7).toString()),
                "$.id");
        mvc.perform(as(teacher, post("/api/targets")).content(target(amina, period, "")))
                .andExpect(status().isCreated());
        UUID earlier = openLesson(teacher, classId, LocalDate.now().minusDays(2).toString(), "10:00", "12:00");
        UUID latest = openLesson(teacher, classId, TODAY, "10:00", "12:00");
        for (Object[] lesson : new Object[][] {{earlier, "3"}, {latest, "4.5"}}) {
            mvc.perform(as(teacher, put("/api/lessons/{id}/progress", lesson[0]))
                            .content("{\"subject\":\"QURAN_RECITATION\",\"entries\":[{\"studentId\":\"" + amina
                                    + "\",\"score\":" + lesson[1] + "}]}"))
                    .andExpect(status().isOk());
        }

        mvc.perform(as(teacher, get("/api/progress/classes/{id}", classId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.period.id").value(period))
                .andExpect(jsonPath("$.students", hasSize(2)))
                .andExpect(jsonPath("$.students[0].firstName").value("Amina"))
                .andExpect(jsonPath("$.students[0].latestScore.score").value(4.5))
                .andExpect(jsonPath("$.students[0].latestScore.label").value("Very Good"))
                .andExpect(jsonPath("$.students[0].targets", hasSize(1)))
                .andExpect(jsonPath("$.students[1].latestScore").doesNotExist())
                .andExpect(jsonPath("$.students[1].targets", hasSize(0)));
    }
}
