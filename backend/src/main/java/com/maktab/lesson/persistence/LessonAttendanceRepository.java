package com.maktab.lesson.persistence;

import com.maktab.lesson.domain.LessonAttendance;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LessonAttendanceRepository extends JpaRepository<LessonAttendance, UUID> {

    List<LessonAttendance> findByLessonId(UUID lessonId);

    List<LessonAttendance> findByLessonIdIn(Collection<UUID> lessonIds);

    /** A student's attendance with the lesson it belongs to, newest lesson first. */
    @Query("""
            select l.id as lessonId, l.lessonDate as lessonDate, l.startTime as startTime,
                   l.classGroupId as classGroupId, a.status as status, a.minutesLate as minutesLate,
                   a.absenceReason as absenceReason, a.note as note
            from LessonAttendance a join Lesson l on l.id = a.lessonId
            where a.studentId = :studentId
              and (:from is null or l.lessonDate >= :from)
              and (:to is null or l.lessonDate <= :to)
            order by l.lessonDate desc, l.startTime desc
            """)
    List<StudentAttendanceRow> findForStudent(@Param("studentId") UUID studentId, @Param("from") LocalDate from,
            @Param("to") LocalDate to);

    /** Counts per status for one student, used to calculate the attendance percentage without storing it. */
    @Query("""
            select a.status as status, count(a) as total from LessonAttendance a
            join Lesson l on l.id = a.lessonId
            where a.studentId in :studentIds
              and (:from is null or l.lessonDate >= :from)
              and (:to is null or l.lessonDate <= :to)
            group by a.status
            """)
    List<StatusCount> countByStatus(@Param("studentIds") Collection<UUID> studentIds,
            @Param("from") LocalDate from, @Param("to") LocalDate to);

    interface StudentAttendanceRow {
        UUID getLessonId();

        LocalDate getLessonDate();

        java.time.LocalTime getStartTime();

        UUID getClassGroupId();

        com.maktab.lesson.domain.AttendanceStatus getStatus();

        Short getMinutesLate();

        com.maktab.lesson.domain.AbsenceReason getAbsenceReason();

        String getNote();
    }

    interface StatusCount {
        com.maktab.lesson.domain.AttendanceStatus getStatus();

        long getTotal();
    }
}
