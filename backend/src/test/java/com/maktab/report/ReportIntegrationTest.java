package com.maktab.report;

import static org.hamcrest.Matchers.contains;
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

/** Reports count only what the caller may see, calculate their figures on read, and keep fees from teachers. */
class ReportIntegrationTest extends SchoolApi {

    private static final LocalDate TODAY = LocalDate.now();

    private void register(Session actor, UUID lessonId, String entries) throws Exception {
        mvc.perform(as(actor, put("/api/lessons/{id}/attendance", lessonId)).content("{\"entries\":[" + entries + "]}"))
                .andExpect(status().isOk());
    }

    private static String entry(UUID studentId, String status) {
        return "{\"studentId\":\"" + studentId + "\",\"status\":\"" + status + "\""
                + ("LATE".equals(status) ? ",\"minutesLate\":5" : "")
                + ("ABSENT".equals(status) ? ",\"absenceReason\":\"SICK\"" : "") + "}";
    }

    private UUID lesson(Session actor, UUID classId, LocalDate date) throws Exception {
        return openLesson(actor, classId, date.toString(), "10:00", "12:00");
    }

    @Test
    void attendanceIsCountedPerClassAndStudentsBelowTheThresholdAreListed() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        UUID amina = createStudent(admin, "Amina", classId, null);
        UUID bilal = createStudent(admin, "Bilal", classId, null);
        UUID lastWeek = lesson(teacher, classId, TODAY.minusDays(7));
        UUID today = lesson(teacher, classId, TODAY);
        register(teacher, lastWeek, entry(amina, "PRESENT") + "," + entry(bilal, "ABSENT"));
        register(teacher, today, entry(amina, "PRESENT") + "," + entry(bilal, "LATE"));
        // A lesson before the range is left out.
        register(teacher, lesson(teacher, classId, TODAY.minusDays(40)), entry(bilal, "ABSENT"));

        mvc.perform(as(teacher, get("/api/reports/attendance")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.from").value(TODAY.minusDays(27).toString()))
                .andExpect(jsonPath("$.to").value(TODAY.toString()))
                .andExpect(jsonPath("$.thresholdPercentage").value(80))
                .andExpect(jsonPath("$.totals.lessons").value(2))
                .andExpect(jsonPath("$.totals.records").value(4))
                .andExpect(jsonPath("$.totals.present").value(2))
                .andExpect(jsonPath("$.totals.late").value(1))
                .andExpect(jsonPath("$.totals.absent").value(1))
                .andExpect(jsonPath("$.totals.attendancePercentage").value(75))
                .andExpect(jsonPath("$.absenceReasons.SICK").value(1))
                .andExpect(jsonPath("$.classes", hasSize(1)))
                .andExpect(jsonPath("$.classes[0].classId").value(classId.toString()))
                .andExpect(jsonPath("$.classes[0].counts.attendancePercentage").value(75))
                .andExpect(jsonPath("$.belowThreshold", hasSize(1)))
                .andExpect(jsonPath("$.belowThreshold[0].firstName").value("Bilal"))
                .andExpect(jsonPath("$.belowThreshold[0].counts.attendancePercentage").value(50));

        // A longer range takes the older lesson in.
        mvc.perform(as(teacher, get("/api/reports/attendance").param("classId", classId.toString())
                        .param("from", TODAY.minusDays(60).toString())))
                .andExpect(jsonPath("$.totals.lessons").value(3))
                .andExpect(jsonPath("$.belowThreshold[0].counts.attendancePercentage").value(33));

        mvc.perform(as(teacher, get("/api/reports/attendance").param("from", TODAY.toString())
                        .param("to", TODAY.minusDays(1).toString())))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.from").isNotEmpty());
        mvc.perform(as(teacher, get("/api/reports/attendance").param("from", TODAY.minusYears(2).toString())))
                .andExpect(status().isBadRequest());
    }

    @Test
    void aTeacherOnlyReportsOnTheirOwnClasses() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID mine = createClass(admin);
        UUID other = createClass(admin);
        assignTeachers(admin, mine, teacher.user().id());
        UUID amina = createStudent(admin, "Amina", mine, null);
        UUID yusuf = createStudent(admin, "Yusuf", other, null);
        register(admin, lesson(admin, mine, TODAY), entry(amina, "PRESENT"));
        register(admin, lesson(admin, other, TODAY), entry(yusuf, "ABSENT"));

        mvc.perform(as(teacher, get("/api/reports/attendance")))
                .andExpect(jsonPath("$.classes[*].classId", contains(mine.toString())))
                .andExpect(jsonPath("$.totals.absent").value(0));
        for (String report : new String[] {"attendance", "behaviour", "progress"}) {
            mvc.perform(as(teacher, get("/api/reports/" + report).param("classId", other.toString())))
                    .andExpect(status().isNotFound());
        }
        mvc.perform(as(teacher, get("/api/reports/students/{id}", yusuf))).andExpect(status().isNotFound());

        // An admin sees the other class.
        mvc.perform(as(admin, get("/api/reports/attendance").param("classId", other.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totals.absent").value(1));
    }

    @Test
    void progressShowsTheCurrentPeriodAndWhoIsBehindTheirTarget() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID levelId = createLevel(admin);
        UUID classId = createClassInLevel(admin, levelId);
        assignTeachers(admin, classId, teacher.user().id());
        UUID amina = createStudent(admin, "Amina", classId, null);
        UUID bilal = createStudent(admin, "Bilal", classId, null);
        createPeriod(admin, levelId, 1, TODAY.minusDays(35).toString());
        String current = JsonPath.read(createPeriod(admin, levelId, 2, TODAY.minusDays(7).toString()), "$.id");
        for (Object[] target : new Object[][] {{amina, 60}, {bilal, 90}}) {
            mvc.perform(as(teacher, post("/api/targets")).content("{\"studentId\":\"" + target[0]
                            + "\",\"curriculumPeriodId\":\"" + current + "\",\"subject\":\"QURAN_RECITATION\","
                            + "\"description\":\"Recite Surah Al-Fatiha\",\"targetPercentage\":85,"
                            + "\"currentPercentage\":" + target[1] + "}"))
                    .andExpect(status().isCreated());
        }
        UUID lessonId = lesson(teacher, classId, TODAY);
        mvc.perform(as(teacher, put("/api/lessons/{id}/progress", lessonId))
                        .content("{\"subject\":\"QURAN_RECITATION\",\"entries\":["
                                + "{\"studentId\":\"" + amina + "\",\"score\":3.5},"
                                + "{\"studentId\":\"" + bilal + "\",\"score\":4}]}"))
                .andExpect(status().isOk());

        mvc.perform(as(teacher, get("/api/reports/progress").param("classId", classId.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.classes", hasSize(1)))
                .andExpect(jsonPath("$.classes[0].period.number").value(2))
                .andExpect(jsonPath("$.classes[0].students").value(2))
                .andExpect(jsonPath("$.classes[0].scores").value(2))
                .andExpect(jsonPath("$.classes[0].averageScore").value(3.8))
                .andExpect(jsonPath("$.classes[0].targets").value(2))
                .andExpect(jsonPath("$.classes[0].targetsBehind").value(1))
                .andExpect(jsonPath("$.behindTarget", hasSize(1)))
                .andExpect(jsonPath("$.behindTarget[0].firstName").value("Amina"))
                .andExpect(jsonPath("$.behindTarget[0].currentPercentage").value(60))
                .andExpect(jsonPath("$.periods[*].period.number", contains(1, 2)))
                .andExpect(jsonPath("$.periods[1].averageScore").value(3.8));

        mvc.perform(as(teacher, get("/api/reports/progress")))
                .andExpect(jsonPath("$.classes[*].classId", contains(classId.toString())))
                .andExpect(jsonPath("$.periods", hasSize(0)));
    }

    @Test
    void aBehaviourThatNeedsAttentionIsRecurringFromThreeTimes() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        UUID amina = createStudent(admin, "Amina", classId, null);
        UUID bilal = createStudent(admin, "Bilal", classId, null);
        for (int week = 0; week < 3; week++) {
            UUID lessonId = lesson(teacher, classId, TODAY.minusDays(7L * week));
            String bilalBehaviour = week == 0 ? "\"TALKING\"" : "\"RESPECTFUL\"";
            mvc.perform(as(teacher, put("/api/lessons/{id}/behaviour", lessonId))
                            .content("{\"entries\":[{\"studentId\":\"" + amina + "\",\"behaviours\":[\"TALKING\"]},"
                                    + "{\"studentId\":\"" + bilal + "\",\"behaviours\":[" + bilalBehaviour + "]}]}"))
                    .andExpect(status().isOk());
        }

        mvc.perform(as(teacher, get("/api/reports/behaviour").param("classId", classId.toString())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.observations").value(6))
                .andExpect(jsonPath("$.recurringAtLeast").value(3))
                .andExpect(jsonPath("$.behaviours[0].behaviour").value("TALKING"))
                .andExpect(jsonPath("$.behaviours[0].count").value(4))
                .andExpect(jsonPath("$.behaviours[0].good").value(false))
                .andExpect(jsonPath("$.behaviours[1].behaviour").value("RESPECTFUL"))
                .andExpect(jsonPath("$.behaviours[1].good").value(true))
                .andExpect(jsonPath("$.recurring", hasSize(1)))
                .andExpect(jsonPath("$.recurring[0].firstName").value("Amina"))
                .andExpect(jsonPath("$.recurring[0].count").value(3))
                .andExpect(jsonPath("$.recurring[0].lastSeen").value(TODAY.toString()));
    }

    @Test
    void feesStayOutOfTeachersReports() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID classId = createClass(admin);
        assignTeachers(admin, classId, teacher.user().id());
        UUID amina = createStudent(admin, "Amina", classId, null);
        register(teacher, lesson(teacher, classId, TODAY), entry(amina, "LATE"));

        mvc.perform(as(teacher, get("/api/reports/payments"))).andExpect(status().isForbidden());
        mvc.perform(as(teacher, get("/api/reports/students/{id}", amina)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.firstName").value("Amina"))
                .andExpect(jsonPath("$.attendance.lessons").value(1))
                .andExpect(jsonPath("$.attendance.late").value(1))
                .andExpect(jsonPath("$.attendance.attendancePercentage").value(100))
                .andExpect(jsonPath("$.payments").doesNotExist());
        mvc.perform(as(teacher, get("/api/reports/dashboard")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.attendance.late").value(1))
                .andExpect(jsonPath("$.attendance.attendancePercentage").value(100))
                .andExpect(jsonPath("$.payments").doesNotExist());

        mvc.perform(as(admin, get("/api/reports/payments")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currency").value("GBP"));
        mvc.perform(as(admin, get("/api/reports/students/{id}", amina)))
                .andExpect(jsonPath("$.payments.currency").value("GBP"))
                .andExpect(jsonPath("$.payments.outstandingTotal").value(0.0));
    }

    @Test
    void theStudentReportCoversTheChosenDates() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID amina = createStudent(admin, "Amina", classId, null);
        UUID old = lesson(admin, classId, TODAY.minusDays(30));
        UUID recent = lesson(admin, classId, TODAY.minusDays(2));
        register(admin, old, entry(amina, "ABSENT"));
        register(admin, recent, entry(amina, "PRESENT"));
        mvc.perform(as(admin, put("/api/lessons/{id}/progress", recent))
                        .content("{\"subject\":\"ARABIC\",\"entries\":[{\"studentId\":\"" + amina + "\",\"score\":4.5}]}"))
                .andExpect(status().isOk());
        mvc.perform(as(admin, put("/api/lessons/{id}/uniform", recent))
                        .content("{\"entries\":[{\"studentId\":\"" + amina + "\",\"status\":\"NOT_IN_ORDER\"}]}"))
                .andExpect(status().isOk());

        mvc.perform(as(admin, get("/api/reports/students/{id}", amina)))
                .andExpect(jsonPath("$.attendance.lessons").value(1))
                .andExpect(jsonPath("$.attendance.belowThreshold").value(false))
                .andExpect(jsonPath("$.progress[0].subject").value("ARABIC"))
                .andExpect(jsonPath("$.progress[0].averageScore").value(4.5))
                .andExpect(jsonPath("$.progress[0].latestLabel").value("Very Good"))
                .andExpect(jsonPath("$.uniform.notInOrder").value(1));
        mvc.perform(as(admin, get("/api/reports/students/{id}", amina)
                        .param("from", TODAY.minusDays(45).toString())))
                .andExpect(jsonPath("$.attendance.lessons").value(2))
                .andExpect(jsonPath("$.attendance.attendancePercentage").value(50))
                .andExpect(jsonPath("$.attendance.belowThreshold").value(true))
                .andExpect(jsonPath("$.attendance.absenceReasons.SICK").value(1));
    }
}
