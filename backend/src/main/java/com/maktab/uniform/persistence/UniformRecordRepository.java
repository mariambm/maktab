package com.maktab.uniform.persistence;

import com.maktab.uniform.domain.UniformRecord;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UniformRecordRepository extends JpaRepository<UniformRecord, UUID> {

    List<UniformRecord> findByLessonId(UUID lessonId);

    /** A student's uniform records with the lesson they belong to, newest lesson first. */
    @Query("""
            select u as record, l.lessonDate as lessonDate, l.classGroupId as classGroupId
            from UniformRecord u join Lesson l on l.id = u.lessonId
            where u.studentId = :studentId
            order by l.lessonDate desc, l.startTime desc
            """)
    List<StudentUniformRow> findForStudent(@Param("studentId") UUID studentId);

    interface StudentUniformRow {
        UniformRecord getRecord();

        LocalDate getLessonDate();

        UUID getClassGroupId();
    }
}
