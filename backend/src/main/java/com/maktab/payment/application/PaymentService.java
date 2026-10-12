package com.maktab.payment.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.classgroup.application.AccessScopeService;
import com.maktab.classgroup.domain.ClassEnrollment;
import com.maktab.classgroup.domain.ClassGroup;
import com.maktab.classgroup.persistence.ClassEnrollmentRepository;
import com.maktab.classgroup.persistence.ClassGroupRepository;
import com.maktab.common.AccessScope;
import com.maktab.common.BusinessValidationException;
import com.maktab.common.ConflictException;
import com.maktab.common.NotFoundException;
import com.maktab.common.PageResponse;
import com.maktab.common.SearchTerms;
import com.maktab.organisation.application.OrganisationCalendar;
import com.maktab.organisation.domain.Organisation;
import com.maktab.organisation.persistence.OrganisationRepository;
import com.maktab.parent.domain.ParentGuardian;
import com.maktab.parent.persistence.ParentGuardianRepository;
import com.maktab.payment.api.CreatePaymentPeriodRequest;
import com.maktab.payment.api.PaymentPeriodResponse;
import com.maktab.payment.api.PaymentResponse;
import com.maktab.payment.api.StudentsAddedResponse;
import com.maktab.payment.api.UpdatePaymentPeriodRequest;
import com.maktab.payment.api.UpdatePaymentRequest;
import com.maktab.payment.domain.Payment;
import com.maktab.payment.domain.PaymentPeriod;
import com.maktab.payment.domain.PaymentStatus;
import com.maktab.payment.persistence.PaymentPeriodRepository;
import com.maktab.payment.persistence.PaymentRepository;
import com.maktab.student.application.StudentAccess;
import com.maktab.student.domain.Student;
import com.maktab.student.domain.StudentParent;
import com.maktab.student.persistence.StudentParentRepository;
import com.maktab.student.persistence.StudentRepository;
import java.math.BigDecimal;
import java.time.YearMonth;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Monthly fees. Opening a month charges every student who was enrolled during it the month's fee; payments are then
 * recorded per student. Someone who may only see some classes (a teacher granted payment access) sees and changes
 * only their own students' payments, and cannot open months or change the fee.
 */
@Service
public class PaymentService {

    private static final String PERIOD = "PaymentPeriod";
    private static final String PAYMENT = "Payment";

    private final PaymentPeriodRepository periods;
    private final PaymentRepository payments;
    private final StudentRepository students;
    private final StudentParentRepository studentParents;
    private final ParentGuardianRepository parents;
    private final ClassEnrollmentRepository enrollments;
    private final ClassGroupRepository classes;
    private final OrganisationRepository organisations;
    private final OrganisationCalendar calendar;
    private final StudentAccess studentAccess;
    private final AccessScopeService scopes;
    private final AuditService audit;

    public PaymentService(PaymentPeriodRepository periods, PaymentRepository payments, StudentRepository students,
            StudentParentRepository studentParents, ParentGuardianRepository parents,
            ClassEnrollmentRepository enrollments, ClassGroupRepository classes, OrganisationRepository organisations,
            OrganisationCalendar calendar, StudentAccess studentAccess, AccessScopeService scopes,
            AuditService audit) {
        this.periods = periods;
        this.payments = payments;
        this.students = students;
        this.studentParents = studentParents;
        this.parents = parents;
        this.enrollments = enrollments;
        this.classes = classes;
        this.organisations = organisations;
        this.calendar = calendar;
        this.studentAccess = studentAccess;
        this.scopes = scopes;
        this.audit = audit;
    }

    /** Every month, the latest first, with its totals. */
    @Transactional(readOnly = true)
    public List<PaymentPeriodResponse> periods(CurrentUser actor) {
        return toResponses(actor, periods.findByOrganisationIdOrderByMonthDesc(actor.organisationId()));
    }

    @Transactional(readOnly = true)
    public PaymentPeriodResponse period(CurrentUser actor, UUID id) {
        return toResponses(actor, List.of(loadPeriod(actor, id))).getFirst();
    }

    @Transactional
    public PaymentPeriodResponse createPeriod(CurrentUser actor, CreatePaymentPeriodRequest request) {
        requireWholeOrganisation(actor);
        YearMonth month = request.month();
        if (periods.existsByOrganisationIdAndMonth(actor.organisationId(), month.atDay(1))) {
            throw new ConflictException("This month has already been added");
        }
        PaymentPeriod period = new PaymentPeriod(actor.organisationId(), month, request.monthlyFee(), actor.id());
        periods.save(period);
        int charged = chargeNewStudents(actor, period);
        audit.record(actor, AuditAction.PAYMENT_PERIOD_CREATED, PERIOD, period.getId(), null,
                Map.of("month", month.toString(), "monthlyFee", period.getMonthlyFee(), "students", charged));
        return toResponses(actor, List.of(period)).getFirst();
    }

    /**
     * Changes the month's fee, and the amount expected from every student still on the old fee. Students given their
     * own amount keep it.
     */
    @Transactional
    public PaymentPeriodResponse changeFee(CurrentUser actor, UUID id, UpdatePaymentPeriodRequest request) {
        requireWholeOrganisation(actor);
        PaymentPeriod period = loadPeriod(actor, id);
        BigDecimal oldFee = period.getMonthlyFee();
        BigDecimal newFee = request.monthlyFee();
        List<Payment> onOldFee = payments.findByPaymentPeriodId(id).stream()
                .filter(p -> p.getExpectedAmount().compareTo(oldFee) == 0)
                .toList();
        if (onOldFee.stream().anyMatch(p -> p.getAmountPaid().compareTo(newFee) > 0)) {
            throw new BusinessValidationException("monthlyFee",
                    "Some students have already paid more than this; change their payment first");
        }
        onOldFee.forEach(p -> p.changeExpectedAmount(newFee));
        period.changeFee(newFee);
        periods.flush();
        audit.record(actor, AuditAction.PAYMENT_PERIOD_UPDATED, PERIOD, id, Map.of("monthlyFee", oldFee),
                Map.of("monthlyFee", newFee, "studentsUpdated", onOldFee.size()));
        return toResponses(actor, List.of(period)).getFirst();
    }

    /** Charges students who were enrolled during the month but joined after it was opened. Safe to repeat. */
    @Transactional
    public StudentsAddedResponse addNewStudents(CurrentUser actor, UUID id) {
        requireWholeOrganisation(actor);
        PaymentPeriod period = loadPeriod(actor, id);
        int added = chargeNewStudents(actor, period);
        if (added > 0) {
            audit.record(actor, AuditAction.PAYMENT_PERIOD_UPDATED, PERIOD, id, null, Map.of("studentsAdded", added));
        }
        return new StudentsAddedResponse(added, toResponses(actor, List.of(period)).getFirst());
    }

    /** Payments of one month or one student, filtered by status, class and name, newest month first. */
    @Transactional(readOnly = true)
    public PageResponse<PaymentResponse> search(CurrentUser actor, UUID periodId, UUID studentId,
            PaymentStatus status, UUID classId, String search, int page, int size) {
        if (studentId != null) {
            studentAccess.requireInScope(actor, studentId);
        }
        if (periodId != null) {
            loadPeriod(actor, periodId);
        }
        AccessScope scope = scopes.scopeFor(actor);
        Page<Payment> result = payments.search(actor.organisationId(), periodId, studentId,
                SearchTerms.containsPattern(search), status == null ? null : status.name(), classId,
                scope.allClasses(), scope.queryClassIds(), PageRequest.of(page, size));
        Function<Payment, PaymentResponse> mapper = mapperFor(actor, result.getContent());
        return PageResponse.of(result, mapper);
    }

    @Transactional
    public PaymentResponse update(CurrentUser actor, UUID id, UpdatePaymentRequest request) {
        Payment payment = loadPayment(actor, id);
        BigDecimal expected = request.expectedAmount();
        BigDecimal paid = request.amountPaid();
        if (paid.compareTo(expected) > 0) {
            throw new BusinessValidationException("amountPaid", "This is more than the amount expected");
        }
        if (paid.signum() > 0) {
            if (request.paidOn() == null) {
                throw new BusinessValidationException("paidOn", "Enter the date it was paid");
            }
            if (request.paidOn().isAfter(calendar.today(actor.organisationId()))) {
                throw new BusinessValidationException("paidOn", "The date cannot be in the future");
            }
            if (request.method() == null) {
                throw new BusinessValidationException("method", "Choose how it was paid");
            }
        }
        UUID payerId = request.parentGuardianId();
        if (payerId != null && studentParents.findByIdStudentId(payment.getStudentId()).stream()
                .noneMatch(link -> link.getParentGuardianId().equals(payerId))) {
            throw new BusinessValidationException("parentGuardianId", "Choose one of the student's parents");
        }
        Map<String, Object> before = snapshot(payment);
        payment.update(expected, paid, request.paidOn(), request.method(), payerId, blankToNull(request.note()),
                actor.id());
        payments.flush();
        audit.record(actor, AuditAction.PAYMENT_UPDATED, PAYMENT, id, before, snapshot(payment));
        return mapperFor(actor, List.of(payment)).apply(payment);
    }

    /** Takes a student off a month, for example one who left before it began. Only when nothing was received. */
    @Transactional
    public void remove(CurrentUser actor, UUID id) {
        Payment payment = loadPayment(actor, id);
        if (payment.getAmountPaid().signum() > 0) {
            throw new ConflictException("A payment has been received for this month; set it to zero first");
        }
        Map<String, Object> before = snapshot(payment);
        payments.delete(payment);
        audit.record(actor, AuditAction.PAYMENT_REMOVED, PAYMENT, id, before, null);
    }

    private int chargeNewStudents(CurrentUser actor, PaymentPeriod period) {
        YearMonth month = period.getMonth();
        Set<UUID> alreadyCharged = payments.findByPaymentPeriodId(period.getId()).stream()
                .map(Payment::getStudentId).collect(Collectors.toSet());
        List<UUID> toCharge = payments.findStudentsToCharge(actor.organisationId(), month.atDay(1),
                        month.atEndOfMonth()).stream()
                .filter(studentId -> !alreadyCharged.contains(studentId))
                .toList();
        if (toCharge.isEmpty()) {
            return 0;
        }
        Map<UUID, UUID> primaryContact = studentParents.findByIdStudentIdInAndPrimaryContactTrue(toCharge).stream()
                .collect(Collectors.toMap(StudentParent::getStudentId, StudentParent::getParentGuardianId));
        payments.saveAll(toCharge.stream()
                .map(studentId -> new Payment(period.getId(), studentId, primaryContact.get(studentId),
                        period.getMonthlyFee()))
                .toList());
        return toCharge.size();
    }

    private PaymentPeriod loadPeriod(CurrentUser actor, UUID id) {
        return periods.findByIdAndOrganisationId(id, actor.organisationId())
                .orElseThrow(() -> new NotFoundException(PERIOD));
    }

    private Payment loadPayment(CurrentUser actor, UUID id) {
        AccessScope scope = scopes.scopeFor(actor);
        return payments.findInScope(id, actor.organisationId(), scope.allClasses(), scope.queryClassIds())
                .orElseThrow(() -> new NotFoundException(PAYMENT));
    }

    /** Opening months and setting the fee affect every student, so they need access to every class. */
    private void requireWholeOrganisation(CurrentUser actor) {
        if (!scopes.scopeFor(actor).allClasses()) {
            throw new AccessDeniedException("Only administrators can add months or change the fee");
        }
    }

    private List<PaymentPeriodResponse> toResponses(CurrentUser actor, List<PaymentPeriod> list) {
        if (list.isEmpty()) {
            return List.of();
        }
        String currency = currencyOf(actor);
        AccessScope scope = scopes.scopeFor(actor);
        Map<UUID, PaymentRepository.PeriodTotalsRow> totals = payments.totals(
                        list.stream().map(PaymentPeriod::getId).toList(), scope.allClasses(), scope.queryClassIds())
                .stream()
                .collect(Collectors.toMap(PaymentRepository.PeriodTotalsRow::getPeriodId, Function.identity()));
        return list.stream()
                .map(p -> new PaymentPeriodResponse(p.getId(), p.getMonth(), p.getMonthlyFee(), currency,
                        toTotals(totals.get(p.getId()))))
                .toList();
    }

    private String currencyOf(CurrentUser actor) {
        return organisations.findById(actor.organisationId()).map(Organisation::getCurrency).orElse("GBP");
    }

    private static PaymentPeriodResponse.Totals toTotals(PaymentRepository.PeriodTotalsRow row) {
        if (row == null) {
            return PaymentPeriodResponse.Totals.NONE;
        }
        BigDecimal expected = row.getExpectedTotal();
        BigDecimal paid = row.getPaidTotal();
        return new PaymentPeriodResponse.Totals(row.getStudents(), row.getPaid(), row.getPartiallyPaid(),
                row.getOutstanding(), expected, paid, expected.subtract(paid));
    }

    /** Loads the students, classes, payers and months of a page at once rather than per row. */
    private Function<Payment, PaymentResponse> mapperFor(CurrentUser actor, Collection<Payment> page) {
        String currency = currencyOf(actor);
        Set<UUID> studentIds = page.stream().map(Payment::getStudentId).collect(Collectors.toSet());
        Map<UUID, Student> studentById = students.findByIdIn(studentIds).stream()
                .collect(Collectors.toMap(Student::getId, Function.identity()));
        Map<UUID, UUID> classOfStudent = new HashMap<>();
        for (ClassEnrollment enrollment : enrollments.findByStudentIdInAndEndDateIsNull(studentIds)) {
            classOfStudent.put(enrollment.getStudentId(), enrollment.getClassGroupId());
        }
        Map<UUID, String> className = classes.findAllById(new HashSet<>(classOfStudent.values())).stream()
                .collect(Collectors.toMap(ClassGroup::getId, ClassGroup::getName));
        Map<UUID, ParentGuardian> payerById = parents.findAllById(page.stream().map(Payment::getParentGuardianId)
                        .filter(Objects::nonNull).collect(Collectors.toSet())).stream()
                .collect(Collectors.toMap(ParentGuardian::getId, Function.identity()));
        Map<UUID, YearMonth> monthOf = periods.findAllById(page.stream().map(Payment::getPaymentPeriodId)
                        .collect(Collectors.toSet())).stream()
                .collect(Collectors.toMap(PaymentPeriod::getId, PaymentPeriod::getMonth));
        return payment -> {
            Student student = studentById.get(payment.getStudentId());
            ParentGuardian payer = payerById.get(payment.getParentGuardianId());
            return new PaymentResponse(payment.getId(), payment.getPaymentPeriodId(),
                    monthOf.get(payment.getPaymentPeriodId()), student.getId(), student.getFirstName(),
                    student.getLastName(), className.get(classOfStudent.get(student.getId())),
                    payer == null ? null
                            : new PaymentResponse.Payer(payer.getId(), payer.getFirstName(), payer.getLastName()),
                    payment.getExpectedAmount(), payment.getAmountPaid(), payment.getOutstandingAmount(), currency,
                    payment.getStatus(), payment.getPaidOn(), payment.getMethod(), payment.getNote());
        };
    }

    /** Amounts, date, method and payer; the free-text note stays out of the audit log. */
    private static Map<String, Object> snapshot(Payment payment) {
        Map<String, Object> values = new HashMap<>();
        values.put("studentId", payment.getStudentId());
        values.put("expectedAmount", payment.getExpectedAmount());
        values.put("amountPaid", payment.getAmountPaid());
        values.put("status", payment.getStatus());
        values.put("paidOn", payment.getPaidOn());
        values.put("method", payment.getMethod());
        values.put("parentGuardianId", payment.getParentGuardianId());
        return values;
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
