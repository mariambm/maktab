package com.maktab.payment.persistence;

import com.maktab.payment.domain.Payment;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Payment queries take the caller's access scope like student queries do: unless {@code allClasses} is set, a
 * payment is only found when its student's current enrolment is in one of {@code classIds}. The status filter is
 * worked out from the amounts, since the status itself is never stored.
 */
public interface PaymentRepository extends JpaRepository<Payment, UUID> {

    String SCOPED_FILTERS = """
            from Payment p
            join Student s on s.id = p.studentId
            join PaymentPeriod pp on pp.id = p.paymentPeriodId
            where pp.organisationId = :organisationId
              and (:periodId is null or p.paymentPeriodId = :periodId)
              and (:studentId is null or p.studentId = :studentId)
              and (:search is null or s.searchName like :search escape '\\')
              and (:status is null
                    or (:status = 'PAID' and p.amountPaid >= p.expectedAmount)
                    or (:status = 'PARTIALLY_PAID' and p.amountPaid > 0 and p.amountPaid < p.expectedAmount)
                    or (:status = 'OUTSTANDING' and p.amountPaid = 0))
              and (:classId is null or exists (
                    select 1 from ClassEnrollment e
                    where e.studentId = s.id and e.endDate is null and e.classGroupId = :classId))
              and (:allClasses = true or exists (
                    select 1 from ClassEnrollment e
                    where e.studentId = s.id and e.endDate is null and e.classGroupId in :classIds))
            """;

    @Query(value = "select p " + SCOPED_FILTERS
            + " order by pp.month desc, lower(s.lastName), lower(s.firstName)",
            countQuery = "select count(p) " + SCOPED_FILTERS)
    Page<Payment> search(@Param("organisationId") UUID organisationId, @Param("periodId") UUID periodId,
            @Param("studentId") UUID studentId, @Param("search") String search, @Param("status") String status,
            @Param("classId") UUID classId, @Param("allClasses") boolean allClasses,
            @Param("classIds") Collection<UUID> classIds, Pageable pageable);

    @Query("""
            select p from Payment p
            join PaymentPeriod pp on pp.id = p.paymentPeriodId
            where p.id = :id and pp.organisationId = :organisationId
              and (:allClasses = true or exists (
                    select 1 from ClassEnrollment e
                    where e.studentId = p.studentId and e.endDate is null and e.classGroupId in :classIds))
            """)
    Optional<Payment> findInScope(@Param("id") UUID id, @Param("organisationId") UUID organisationId,
            @Param("allClasses") boolean allClasses, @Param("classIds") Collection<UUID> classIds);

    /** Totals per month over the payments the caller may see. */
    @Query("""
            select p.paymentPeriodId as periodId, count(p) as students,
                   sum(case when p.amountPaid >= p.expectedAmount then 1 else 0 end) as paid,
                   sum(case when p.amountPaid > 0 and p.amountPaid < p.expectedAmount then 1 else 0 end)
                       as partiallyPaid,
                   sum(case when p.amountPaid = 0 then 1 else 0 end) as outstanding,
                   sum(p.expectedAmount) as expectedTotal, sum(p.amountPaid) as paidTotal
            from Payment p
            where p.paymentPeriodId in :periodIds
              and (:allClasses = true or exists (
                    select 1 from ClassEnrollment e
                    where e.studentId = p.studentId and e.endDate is null and e.classGroupId in :classIds))
            group by p.paymentPeriodId
            """)
    List<PeriodTotalsRow> totals(@Param("periodIds") Collection<UUID> periodIds,
            @Param("allClasses") boolean allClasses, @Param("classIds") Collection<UUID> classIds);

    List<Payment> findByPaymentPeriodId(UUID periodId);

    /**
     * Students to charge for a month: those who were with the mosque during it and in a class at some point of
     * it, so a student who joined later or left earlier is not charged.
     */
    @Query("""
            select s.id from Student s
            where s.organisationId = :organisationId
              and s.joinedOn <= :monthEnd and (s.leftOn is null or s.leftOn >= :monthStart)
              and exists (
                    select 1 from ClassEnrollment e
                    where e.studentId = s.id and e.startDate <= :monthEnd
                      and (e.endDate is null or e.endDate >= :monthStart))
            """)
    List<UUID> findStudentsToCharge(@Param("organisationId") UUID organisationId,
            @Param("monthStart") LocalDate monthStart, @Param("monthEnd") LocalDate monthEnd);

    interface PeriodTotalsRow {
        UUID getPeriodId();

        long getStudents();

        long getPaid();

        long getPartiallyPaid();

        long getOutstanding();

        BigDecimal getExpectedTotal();

        BigDecimal getPaidTotal();
    }
}
