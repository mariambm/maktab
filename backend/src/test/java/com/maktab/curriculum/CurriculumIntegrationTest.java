package com.maktab.curriculum;

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

class CurriculumIntegrationTest extends SchoolApi {

    @Test
    void aPeriodIsFourWeeksWithWeekFourAsReview() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID levelId = createLevel(admin);
        LocalDate start = LocalDate.now().minusDays(7);

        String body = createPeriod(admin, levelId, 1, start.toString());

        org.assertj.core.api.Assertions.assertThat((String) JsonPath.read(body, "$.endDate"))
                .isEqualTo(start.plusDays(27).toString());
        mvc.perform(as(admin, get("/api/curriculum/periods/{id}", UUID.fromString(JsonPath.read(body, "$.id")))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.weeks", hasSize(4)))
                .andExpect(jsonPath("$.weeks[3].review").value(true))
                .andExpect(jsonPath("$.weeks[0].topics[0].learningObjective").isNotEmpty());
    }

    @Test
    void periodsOfOneLevelCannotOverlapOrRepeatANumber() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID levelId = createLevel(admin);
        LocalDate start = LocalDate.now().minusDays(7);
        createPeriod(admin, levelId, 1, start.toString());

        mvc.perform(as(admin, post("/api/curriculum/periods"))
                        .content("{\"curriculumLevelId\":\"" + levelId + "\",\"number\":1,\"name\":\"Again\","
                                + "\"startDate\":\"" + start.plusDays(28) + "\"}"))
                .andExpect(status().isConflict());
        mvc.perform(as(admin, post("/api/curriculum/periods"))
                        .content("{\"curriculumLevelId\":\"" + levelId + "\",\"number\":2,\"name\":\"Overlap\","
                                + "\"startDate\":\"" + start.plusDays(7) + "\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.startDate").isNotEmpty());
    }

    @Test
    void currentPeriodIsTheOneCoveringToday() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID levelId = createLevel(admin);
        createPeriod(admin, levelId, 1, LocalDate.now().minusDays(35).toString());
        createPeriod(admin, levelId, 2, LocalDate.now().minusDays(7).toString());

        mvc.perform(as(admin, get("/api/curriculum/periods/current").param("levelId", levelId.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.number").value(2));
    }

    @Test
    void teachersReadTheCurriculumButCannotChangeIt() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID levelId = createLevel(admin);
        createPeriod(admin, levelId, 1, LocalDate.now().minusDays(7).toString());

        mvc.perform(as(teacher, get("/api/curriculum/periods").param("levelId", levelId.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)));
        mvc.perform(as(teacher, post("/api/curriculum/periods"))
                        .content("{\"curriculumLevelId\":\"" + levelId + "\",\"number\":2,\"name\":\"Mine\","
                                + "\"startDate\":\"" + LocalDate.now().plusDays(21) + "\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    void everyTopicNeedsASubjectFromTheTeachingList() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID levelId = createLevel(admin);
        String start = LocalDate.now().minusDays(7).toString();
        String withoutSubject = "{\"curriculumLevelId\":\"" + levelId + "\",\"number\":1,\"name\":\"P1\","
                + "\"startDate\":\"" + start + "\",\"weeks\":[{\"weekNumber\":1,\"topics\":[{\"title\":\"Wudu\"}]}]}";

        mvc.perform(as(admin, post("/api/curriculum/periods")).content(withoutSubject))
                .andExpect(status().isBadRequest());
        mvc.perform(as(admin, post("/api/curriculum/periods"))
                        .content(withoutSubject.replace("{\"title\"", "{\"subject\":\"MATHS\",\"title\"")))
                .andExpect(status().isBadRequest());
        mvc.perform(as(admin, post("/api/curriculum/periods"))
                        .content(withoutSubject.replace("{\"title\"", "{\"subject\":\"NAMAZ_AND_DUAS\",\"title\"")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.weeks[0].topics[0].subject").value("NAMAZ_AND_DUAS"));
    }

    @Test
    void updatingAPeriodReplacesItsTopics() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID levelId = createLevel(admin);
        LocalDate start = LocalDate.now().minusDays(7);
        UUID periodId = UUID.fromString(JsonPath.read(createPeriod(admin, levelId, 1, start.toString()), "$.id"));

        mvc.perform(as(admin, put("/api/curriculum/periods/{id}", periodId))
                        .content("{\"curriculumLevelId\":\"" + levelId + "\",\"number\":1,\"name\":\"Renamed\","
                                + "\"startDate\":\"" + start + "\",\"weeks\":[{\"weekNumber\":1,\"topics\":["
                                + "{\"subject\":\"QURAN_RECITATION\",\"title\":\"New topic\"}]}]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Renamed"))
                .andExpect(jsonPath("$.weeks", hasSize(4)))
                .andExpect(jsonPath("$.weeks[0].topics", hasSize(1)))
                .andExpect(jsonPath("$.weeks[0].topics[0].title").value("New topic"))
                .andExpect(jsonPath("$.weeks[0].topics[0].subject").value("QURAN_RECITATION"))
                .andExpect(jsonPath("$.weeks[1].topics", hasSize(0)));
    }
}
