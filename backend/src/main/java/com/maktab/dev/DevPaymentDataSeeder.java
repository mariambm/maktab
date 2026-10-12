package com.maktab.dev;

import com.maktab.organisation.application.OrganisationCalendar;
import com.maktab.organisation.domain.Organisation;
import com.maktab.payment.domain.Payment;
import com.maktab.payment.domain.PaymentMethod;
import com.maktab.payment.domain.PaymentPeriod;
import com.maktab.payment.persistence.PaymentPeriodRepository;
import com.maktab.payment.persistence.PaymentRepository;
import com.maktab.student.domain.StudentParent;
import com.maktab.student.persistence.StudentParentRepository;
import com.maktab.user.domain.User;
import com.maktab.user.persistence.UserRepository;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Development-only fees: the last two months and this one at £25, earlier months mostly paid and this month about
 * half, so the Payments screens have every status to show. Runs only with the {@code dev} profile and only when no
 * month exists yet.
 */
@Component
@Profile("dev")
@Order(5)
public class DevPaymentDataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DevPaymentDataSeeder.class);
    private static final BigDecimal FEE = new BigDecimal("25.00");
    private static final PaymentMethod[] METHODS = {PaymentMethod.CASH, PaymentMethod.BANK_TRANSFER,
        PaymentMethod.CASH, PaymentMethod.CARD};

    private final PaymentPeriodRepository periods;
    private final PaymentRepository payments;
    private final StudentParentRepository studentParents;
    private final UserRepository users;
    private final OrganisationCalendar calendar;

    public DevPaymentDataSeeder(PaymentPeriodRepository periods, PaymentRepository payments,
            StudentParentRepository studentParents, UserRepository users, OrganisationCalendar calendar) {
        this.periods = periods;
        this.payments = payments;
        this.studentParents = studentParents;
        this.users = users;
        this.calendar = calendar;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (periods.count() > 0) {
            return;
        }
        UUID recordedBy = users.findByOrganisationIdAndEmail(Organisation.DEFAULT_ID, "administrator1@maktab.local")
                .map(User::getId).orElse(null);
        if (recordedBy == null) {
            return;
        }
        LocalDate today = calendar.today(Organisation.DEFAULT_ID);
        YearMonth thisMonth = YearMonth.from(today);
        int seeded = 0;
        for (int monthsAgo = 2; monthsAgo >= 0; monthsAgo--) {
            YearMonth month = thisMonth.minusMonths(monthsAgo);
            PaymentPeriod period = new PaymentPeriod(Organisation.DEFAULT_ID, month, FEE, recordedBy);
            periods.save(period);
            List<UUID> studentIds = payments.findStudentsToCharge(Organisation.DEFAULT_ID, month.atDay(1),
                    month.atEndOfMonth());
            Map<UUID, UUID> payer = studentParents.findByIdStudentIdInAndPrimaryContactTrue(studentIds).stream()
                    .collect(Collectors.toMap(StudentParent::getStudentId, StudentParent::getParentGuardianId));
            for (int i = 0; i < studentIds.size(); i++) {
                UUID studentId = studentIds.get(i);
                Payment payment = new Payment(period.getId(), studentId, payer.get(studentId), FEE);
                BigDecimal paid = amountPaid(i, monthsAgo);
                LocalDate paidOn = month.atDay(Math.min(3 + i % 8, month.lengthOfMonth()));
                if (paidOn.isAfter(today)) {
                    paidOn = today;
                }
                payment.update(FEE, paid, paidOn, METHODS[i % METHODS.length], payer.get(studentId), null,
                        recordedBy);
                payments.save(payment);
                seeded++;
            }
        }
        log.info("Seeded 3 months of fees with {} payments (fake data)", seeded);
    }

    /** Earlier months: nearly everyone paid. This month: about half paid, a few partly, the rest not yet. */
    private static BigDecimal amountPaid(int i, int monthsAgo) {
        if (monthsAgo > 0) {
            if (i % 11 == 5) {
                return BigDecimal.ZERO;
            }
            return i % 7 == 3 ? new BigDecimal("10.00") : FEE;
        }
        if (i % 2 == 0) {
            return FEE;
        }
        return i % 5 == 1 ? new BigDecimal("15.00") : BigDecimal.ZERO;
    }
}
