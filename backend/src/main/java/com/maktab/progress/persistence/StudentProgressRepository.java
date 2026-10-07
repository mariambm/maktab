package com.maktab.progress.persistence;

import com.maktab.curriculum.domain.Subject;
import com.maktab.progress.domain.StudentProgress;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface StudentProgressRepository extends JpaRepository<StudentProgress, UUID> {

    List<StudentProgress> findByLessonId(UUID lessonId);

    List<StudentProgress> findByLessonIdAndSubject(UUID lessonId, Subject subject);

    /** A student's scores with the lesson they were given in, newest lesson first. */
    @Query("""
            select l.id as lessonId, l.lessonDate as lessonDate, l.classGroupId as classGroupId,
                   p.subject as subject, p.score as score, p.note as note
            from StudentProgress p join Lesson l on l.id = p.lessonId
            where p.studentId = :studentId
            order by l.lessonDate desc, l.startTime desc, p.subject
            """)
    List<StudentProgressRow> findForStudent(@Param("studentId") UUID studentId);

    /** Scores of several students from {@code from} on, newest lesson first. */
    @Query("""
            select p.studentId as studentId, l.lessonDate as lessonDate, p.subject as subject, p.score as score
            from StudentProgress p join Lesson l on l.id = p.lessonId
            where p.studentId in :studentIds and l.lessonDate >= :from
            order by l.lessonDate desc, l.startTime desc
            """)
    List<RecentScoreRow> findRecent(@Param("studentIds") java.util.Collection<UUID> studentIds,
            @Param("from") LocalDate from);

    interface RecentScoreRow {
        UUID getStudentId();

        LocalDate getLessonDate();

        Subject getSubject();

        BigDecimal getScore();
    }

    interface StudentProgressRow {
        UUID getLessonId();

        LocalDate getLessonDate();

        UUID getClassGroupId();

        Subject getSubject();

        BigDecimal getScore();

        String getNote();
    }
}
