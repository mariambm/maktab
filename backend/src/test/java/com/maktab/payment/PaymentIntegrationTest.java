package com.maktab.payment;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.maktab.support.SchoolApi;
import com.maktab.user.domain.Role;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.UUID;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.atomic.AtomicInteger;
import org.junit.jupiter.api.Test;

/**
 * Months of fees, the payments recorded against them, and who may see them. The test database is shared, so every
 * test opens its own month: test students join in September 2026, so later months charge them and earlier ones
 * do not.
 */
class PaymentIntegrationTest extends SchoolApi {

    private static final AtomicInteger NEXT_MONTH =
            new AtomicInteger(ThreadLocalRandom.current().nextInt(12 * 100, 12 * 900));

    /** A month far after the test students joined; each call gives a different one. */
    private static YearMonth futureMonth() {
        return YearMonth.of(2100, 1).plusMonths(NEXT_MONTH.incrementAndGet());
    }

    private String openMonth(Session admin, YearMonth month, String fee) throws Exception {
        return mvc.perform(as(admin, post("/api/payment-periods"))
                        .content("{\"month\":\"" + month + "\",\"monthlyFee\":" + fee + "}"))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
    }

    private String paymentOf(Session session, String periodId, UUID studentId) throws Exception {
        String page = mvc.perform(as(session, get("/api/payments")).param("periodId", periodId)
                        .param("studentId", studentId.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andReturn().getResponse().getContentAsString();
        return JsonPath.read(page, "$.items[0].id");
    }

    private static String payment(String expected, String paid, String extra) {
        return "{\"expectedAmount\":" + expected + ",\"amountPaid\":" + paid + extra + "}";
    }

    @Test
    void openingAMonthChargesEveryEnrolledStudentTheFeeAndTheirPrimaryContactPays() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID parentId = createParent(admin, unique("Rahman"));
        UUID amina = createStudent(admin, "Amina", classId, parentId);
        UUID unenrolled = createStudent(admin, "Yusuf", null, null);
        YearMonth month = futureMonth();

        String period = openMonth(admin, month, "25.00");
        String periodId = JsonPath.read(period, "$.id");
        mvc.perform(as(admin, get("/api/payment-periods/{id}", periodId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.month").value(month.toString()))
                .andExpect(jsonPath("$.monthlyFee").value(25.00))
                .andExpect(jsonPath("$.currency").value("GBP"));
        mvc.perform(as(admin, get("/api/payments")).param("periodId", periodId)
                        .param("studentId", amina.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[0].expectedAmount").value(25.00))
                .andExpect(jsonPath("$.items[0].amountPaid").value(0))
                .andExpect(jsonPath("$.items[0].status").value("OUTSTANDING"))
                .andExpect(jsonPath("$.items[0].payer.id").value(parentId.toString()))
                .andExpect(jsonPath("$.items[0].className").isNotEmpty());
        mvc.perform(as(admin, get("/api/payments")).param("periodId", periodId)
                        .param("studentId", unenrolled.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(0)));

        mvc.perform(as(admin, post("/api/payment-periods"))
                        .content("{\"month\":\"" + month + "\",\"monthlyFee\":30}"))
                .andExpect(status().isConflict());
        mvc.perform(as(admin, post("/api/payment-periods")).content("{\"month\":\"" + futureMonth()
                        + "\",\"monthlyFee\":0}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.monthlyFee").isNotEmpty());
    }

    @Test
    void aMonthBeforeAStudentJoinedDoesNotChargeThem() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID amina = createStudent(admin, "Amina", createClass(admin), null);
        YearMonth beforeJoining = YearMonth.of(2026, 8).minusMonths(ThreadLocalRandom.current().nextInt(12 * 500));

        String periodId = JsonPath.read(openMonth(admin, beforeJoining, "25"), "$.id");

        mvc.perform(as(admin, get("/api/payments")).param("periodId", periodId)
                        .param("studentId", amina.toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(0)));
    }

    @Test
    void recordingAPaymentWorksOutTheStatusAndTheMonthsTotals() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID amina = createStudent(admin, "Amina", classId, null);
        UUID bilal = createStudent(admin, "Bilal", classId, null);
        String periodId = JsonPath.read(openMonth(admin, futureMonth(), "25"), "$.id");
        String aminas = paymentOf(admin, periodId, amina);
        String today = LocalDate.now().toString();

        mvc.perform(as(admin, put("/api/payments/{id}", aminas))
                        .content(payment("25", "10", ",\"paidOn\":\"" + today + "\",\"method\":\"CASH\"")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PARTIALLY_PAID"))
                .andExpect(jsonPath("$.outstandingAmount").value(15.00));
        mvc.perform(as(admin, put("/api/payments/{id}", paymentOf(admin, periodId, bilal)))
                        .content(payment("25", "25", ",\"paidOn\":\"" + today + "\",\"method\":\"BANK_TRANSFER\"")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PAID"));

        mvc.perform(as(admin, get("/api/payments")).param("periodId", periodId).param("classId", classId.toString())
                        .param("status", "PARTIALLY_PAID"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].firstName").value("Amina"));
        // Other tests' students are charged for this month too, so check what these two add up to.
        mvc.perform(as(admin, get("/api/payment-periods/{id}", periodId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totals.paid").value(1))
                .andExpect(jsonPath("$.totals.partiallyPaid").value(1))
                .andExpect(jsonPath("$.totals.paidTotal").value(35.00));

        // Setting it back to zero clears the date and method.
        mvc.perform(as(admin, put("/api/payments/{id}", aminas)).content(payment("25", "0", "")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("OUTSTANDING"))
                .andExpect(jsonPath("$.paidOn").doesNotExist())
                .andExpect(jsonPath("$.method").doesNotExist());
    }

    @Test
    void aPaymentIsCheckedBeforeItIsSaved() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID amina = createStudent(admin, "Amina", createClass(admin), null);
        UUID someoneElsesParent = createParent(admin, unique("Khan"));
        String periodId = JsonPath.read(openMonth(admin, futureMonth(), "25"), "$.id");
        String id = paymentOf(admin, periodId, amina);
        String today = LocalDate.now().toString();

        mvc.perform(as(admin, put("/api/payments/{id}", id))
                        .content(payment("25", "30", ",\"paidOn\":\"" + today + "\",\"method\":\"CASH\"")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.amountPaid").isNotEmpty());
        mvc.perform(as(admin, put("/api/payments/{id}", id)).content(payment("25", "25", ",\"method\":\"CASH\"")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.paidOn").isNotEmpty());
        mvc.perform(as(admin, put("/api/payments/{id}", id))
                        .content(payment("25", "25", ",\"paidOn\":\"" + today + "\"")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.method").isNotEmpty());
        mvc.perform(as(admin, put("/api/payments/{id}", id))
                        .content(payment("25", "25", ",\"paidOn\":\"" + LocalDate.now().plusDays(3)
                                + "\",\"method\":\"CASH\"")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.paidOn").isNotEmpty());
        mvc.perform(as(admin, put("/api/payments/{id}", id))
                        .content(payment("25", "0", ",\"parentGuardianId\":\"" + someoneElsesParent + "\"")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.parentGuardianId").isNotEmpty());
    }

    @Test
    void changingTheFeeMovesStudentsOnTheOldFeeAndAStudentCanOnlyBeRemovedWhileNothingWasPaid() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        UUID classId = createClass(admin);
        UUID amina = createStudent(admin, "Amina", classId, null);
        UUID bilal = createStudent(admin, "Bilal", classId, null);
        String periodId = JsonPath.read(openMonth(admin, futureMonth(), "25"), "$.id");
        String aminas = paymentOf(admin, periodId, amina);
        String bilals = paymentOf(admin, periodId, bilal);
        mvc.perform(as(admin, put("/api/payments/{id}", bilals)).content(payment("15", "0", "")))
                .andExpect(status().isOk());

        mvc.perform(as(admin, put("/api/payment-periods/{id}", periodId)).content("{\"monthlyFee\":30}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.monthlyFee").value(30));
        mvc.perform(as(admin, get("/api/payments")).param("periodId", periodId).param("studentId", amina.toString()))
                .andExpect(jsonPath("$.items[0].expectedAmount").value(30));
        mvc.perform(as(admin, get("/api/payments")).param("periodId", periodId).param("studentId", bilal.toString()))
                .andExpect(jsonPath("$.items[0].expectedAmount").value(15));

        mvc.perform(as(admin, put("/api/payments/{id}", aminas))
                        .content(payment("30", "5", ",\"paidOn\":\"" + LocalDate.now() + "\",\"method\":\"CASH\"")))
                .andExpect(status().isOk());
        mvc.perform(as(admin, delete("/api/payments/{id}", aminas))).andExpect(status().isConflict());
        mvc.perform(as(admin, delete("/api/payments/{id}", bilals))).andExpect(status().isNoContent());

        // Adding new students later puts Bilal back, once, and leaves Amina's payment alone.
        mvc.perform(as(admin, post("/api/payment-periods/{id}/payments", periodId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.added").value(1));
        mvc.perform(as(admin, post("/api/payment-periods/{id}/payments", periodId)))
                .andExpect(jsonPath("$.added").value(0));
        mvc.perform(as(admin, get("/api/payments")).param("periodId", periodId).param("studentId", amina.toString()))
                .andExpect(jsonPath("$.items[0].amountPaid").value(5));
    }

    @Test
    void teachersDoNotSeePaymentsUnlessGrantedAndThenOnlyTheirOwnStudents() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);
        UUID mine = createClass(admin);
        UUID other = createClass(admin);
        assignTeachers(admin, mine, teacher.user().id());
        UUID amina = createStudent(admin, "Amina", mine, null);
        UUID bilal = createStudent(admin, "Bilal", other, null);
        String periodId = JsonPath.read(openMonth(admin, futureMonth(), "25"), "$.id");
        String bilals = paymentOf(admin, periodId, bilal);

        mvc.perform(as(teacher, get("/api/payment-periods"))).andExpect(status().isForbidden());
        mvc.perform(as(teacher, get("/api/payments")).param("periodId", periodId)).andExpect(status().isForbidden());

        mvc.perform(as(admin, put("/api/users/{id}/permissions", teacher.user().id()))
                        .content("{\"permissions\":[\"PAYMENT_READ\",\"PAYMENT_WRITE\"]}"))
                .andExpect(status().isOk());
        Session granted = login(teacher.user());

        mvc.perform(as(granted, get("/api/payments")).param("periodId", periodId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items", hasSize(1)))
                .andExpect(jsonPath("$.items[0].studentId").value(amina.toString()));
        mvc.perform(as(granted, get("/api/payment-periods/{id}", periodId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totals.students").value(1));
        mvc.perform(as(granted, get("/api/payments")).param("studentId", bilal.toString()))
                .andExpect(status().isNotFound());
        mvc.perform(as(granted, put("/api/payments/{id}", bilals)).content(payment("25", "0", "")))
                .andExpect(status().isNotFound());
        mvc.perform(as(granted, delete("/api/payments/{id}", bilals))).andExpect(status().isNotFound());
        mvc.perform(as(granted, post("/api/payment-periods"))
                        .content("{\"month\":\"" + futureMonth() + "\",\"monthlyFee\":25}"))
                .andExpect(status().isForbidden());
        mvc.perform(as(granted, put("/api/payment-periods/{id}", periodId)).content("{\"monthlyFee\":1}"))
                .andExpect(status().isForbidden());
    }
}
