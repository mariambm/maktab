package com.maktab.report.persistence;

import com.maktab.behaviour.domain.Behaviour;
import com.maktab.common.AccessScope;
import com.maktab.curriculum.domain.Subject;
import com.maktab.lesson.domain.AbsenceReason;
import com.maktab.lesson.domain.AttendanceStatus;
import com.maktab.uniform.domain.UniformStatus;
import jakarta.persistence.EntityManager;
import jakarta.persistence.TypedQuery;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Repository;

/**
 * The aggregate queries behind the reports. Every query that spans classes takes the caller's {@link AccessScope}, so
 * rows from classes the caller may not see are filtered out in SQL, the same way the other modules do it. A lesson
 * belongs to the class it was given in, so a teacher's report covers the lessons of their own classes.
 */
@Repository
public class ReportQueries {

    /** Lessons of the organisation in a date range, optionally one class, within the caller's scope. */
    private static final String LESSONS_IN_SCOPE = """
            join Lesson l on l.id = x.lessonId
            join ClassGroup c on c.id = l.classGroupId
            where c.organisationId = :organisationId
              and l.lessonDate between :from and :to
              and (:classId is null or l.classGroupId = :classId)
              and (:allClasses = true or l.classGroupId in :classIds)
            """;

    private final EntityManager entityManager;

    public ReportQueries(EntityManager entityManager) {
        this.entityManager = entityManager;
    }

    public record AttendanceCount(UUID classId, UUID studentId, AttendanceStatus status, AbsenceReason reason,
            long total) {
    }

    public record ClassLessons(UUID classId, long lessons) {
    }

    public record BehaviourCount(UUID studentId, Behaviour behaviour, long total, LocalDate lastSeen) {
    }

    public record ScoreSummary(Subject subject, long scores, Double average) {
    }

    public record LatestScore(Subject subject, LocalDate lessonDate, BigDecimal score) {
    }

    public record UniformCount(UniformStatus status, long total) {
    }

    public record AmountOwed(UUID studentId, String firstName, String lastName, long months, BigDecimal owed) {
    }

    /** Sums are null when the student has no fees in the range. */
    public record StudentPaymentTotals(Long months, Long monthsOwing, BigDecimal expected, BigDecimal paid) {
    }

    /** Attendance rows counted per class, student, status and absence reason. */
    public List<AttendanceCount> attendance(Filter filter) {
        return filter.bind(entityManager.createQuery("""
                select new com.maktab.report.persistence.ReportQueries$AttendanceCount(
                    l.classGroupId, x.studentId, x.status, x.absenceReason, count(x))
                from LessonAttendance x
                """ + LESSONS_IN_SCOPE + """
                group by l.classGroupId, x.studentId, x.status, x.absenceReason
                """, AttendanceCount.class)).getResultList();
    }

    /** How many lessons of each class had their register taken. */
    public List<ClassLessons> registeredLessons(Filter filter) {
        return filter.bind(entityManager.createQuery("""
                select new com.maktab.report.persistence.ReportQueries$ClassLessons(l.classGroupId, count(distinct l))
                from LessonAttendance x
                """ + LESSONS_IN_SCOPE + """
                group by l.classGroupId
                """, ClassLessons.class)).getResultList();
    }

    /** Behaviour observations counted per student and behaviour, with the last lesson each was seen in. */
    public List<BehaviourCount> behaviour(Filter filter) {
        return filter.bind(entityManager.createQuery("""
                select new com.maktab.report.persistence.ReportQueries$BehaviourCount(
                    x.studentId, item, count(x), max(l.lessonDate))
                from BehaviourRecord x join x.behaviours item
                """ + LESSONS_IN_SCOPE + """
                group by x.studentId, item
                """, BehaviourCount.class)).getResultList();
    }

    /** How many behaviour observations (one per student per lesson) were made. */
    public long behaviourRecords(Filter filter) {
        return filter.bind(entityManager.createQuery("select count(x) from BehaviourRecord x " + LESSONS_IN_SCOPE,
                Long.class)).getSingleResult();
    }

    /** The average score per subject of a class over a date range. */
    public List<ScoreSummary> classScores(UUID classId, LocalDate from, LocalDate to) {
        return entityManager.createQuery("""
                select new com.maktab.report.persistence.ReportQueries$ScoreSummary(p.subject, count(p), avg(p.score))
                from StudentProgress p join Lesson l on l.id = p.lessonId
                where l.classGroupId = :classId and l.lessonDate between :from and :to
                group by p.subject
                """, ScoreSummary.class)
                .setParameter("classId", classId).setParameter("from", from).setParameter("to", to)
                .getResultList();
    }

    /** A student's average score per subject over a date range, in any class. */
    public List<ScoreSummary> studentScores(UUID studentId, LocalDate from, LocalDate to) {
        return entityManager.createQuery("""
                select new com.maktab.report.persistence.ReportQueries$ScoreSummary(p.subject, count(p), avg(p.score))
                from StudentProgress p join Lesson l on l.id = p.lessonId
                where p.studentId = :studentId and l.lessonDate between :from and :to
                group by p.subject
                """, ScoreSummary.class)
                .setParameter("studentId", studentId).setParameter("from", from).setParameter("to", to)
                .getResultList();
    }

    /** A student's scores in a date range, newest lesson first. */
    public List<LatestScore> studentScoreHistory(UUID studentId, LocalDate from, LocalDate to) {
        return entityManager.createQuery("""
                select new com.maktab.report.persistence.ReportQueries$LatestScore(p.subject, l.lessonDate, p.score)
                from StudentProgress p join Lesson l on l.id = p.lessonId
                where p.studentId = :studentId and l.lessonDate between :from and :to
                order by l.lessonDate desc, l.startTime desc
                """, LatestScore.class)
                .setParameter("studentId", studentId).setParameter("from", from).setParameter("to", to)
                .getResultList();
    }

    /** A student's behaviour observations per behaviour over a date range. */
    public List<BehaviourCount> studentBehaviour(UUID studentId, LocalDate from, LocalDate to) {
        return entityManager.createQuery("""
                select new com.maktab.report.persistence.ReportQueries$BehaviourCount(
                    x.studentId, item, count(x), max(l.lessonDate))
                from BehaviourRecord x join x.behaviours item join Lesson l on l.id = x.lessonId
                where x.studentId = :studentId and l.lessonDate between :from and :to
                group by x.studentId, item
                """, BehaviourCount.class)
                .setParameter("studentId", studentId).setParameter("from", from).setParameter("to", to)
                .getResultList();
    }

    public List<UniformCount> studentUniform(UUID studentId, LocalDate from, LocalDate to) {
        return entityManager.createQuery("""
                select new com.maktab.report.persistence.ReportQueries$UniformCount(x.status, count(x))
                from UniformRecord x join Lesson l on l.id = x.lessonId
                where x.studentId = :studentId and l.lessonDate between :from and :to
                group by x.status
                """, UniformCount.class)
                .setParameter("studentId", studentId).setParameter("from", from).setParameter("to", to)
                .getResultList();
    }

    /**
     * Students who still owe money for a month from {@code fromMonth} on, most owed first. Scoped like the payments
     * screen: a teacher granted payment access sees the students currently in their classes.
     */
    public List<AmountOwed> amountsOwed(UUID organisationId, LocalDate fromMonth, AccessScope scope) {
        return entityManager.createQuery("""
                select new com.maktab.report.persistence.ReportQueries$AmountOwed(
                    s.id, s.firstName, s.lastName, count(p), sum(p.expectedAmount - p.amountPaid))
                from Payment p
                join Student s on s.id = p.studentId
                join PaymentPeriod pp on pp.id = p.paymentPeriodId
                where pp.organisationId = :organisationId and pp.month >= :fromMonth
                  and p.amountPaid < p.expectedAmount
                  and (:allClasses = true or exists (
                        select 1 from ClassEnrollment e
                        where e.studentId = s.id and e.endDate is null and e.classGroupId in :classIds))
                group by s.id, s.firstName, s.lastName
                order by sum(p.expectedAmount - p.amountPaid) desc, lower(s.lastName), lower(s.firstName)
                """, AmountOwed.class)
                .setParameter("organisationId", organisationId).setParameter("fromMonth", fromMonth)
                .setParameter("allClasses", scope.allClasses()).setParameter("classIds", scope.queryClassIds())
                .getResultList();
    }

    /** One student's fees for the months between {@code fromMonth} and {@code toMonth}. */
    public StudentPaymentTotals studentPayments(UUID studentId, LocalDate fromMonth, LocalDate toMonth) {
        return entityManager.createQuery("""
                select new com.maktab.report.persistence.ReportQueries$StudentPaymentTotals(
                    count(p), sum(case when p.amountPaid < p.expectedAmount then 1 else 0 end),
                    sum(p.expectedAmount), sum(p.amountPaid))
                from Payment p join PaymentPeriod pp on pp.id = p.paymentPeriodId
                where p.studentId = :studentId and pp.month between :fromMonth and :toMonth
                """, StudentPaymentTotals.class)
                .setParameter("studentId", studentId).setParameter("fromMonth", fromMonth)
                .setParameter("toMonth", toMonth)
                .getSingleResult();
    }

    /** Which lessons a report covers: a date range, optionally one class, and the caller's scope. */
    public record Filter(UUID organisationId, LocalDate from, LocalDate to, UUID classId, AccessScope scope) {

        <T> TypedQuery<T> bind(TypedQuery<T> query) {
            return query.setParameter("organisationId", organisationId)
                    .setParameter("from", from)
                    .setParameter("to", to)
                    .setParameter("classId", classId)
                    .setParameter("allClasses", scope.allClasses())
                    .setParameter("classIds", scope.queryClassIds());
        }
    }
}
