package com.maktab.behaviour.persistence;

import com.maktab.behaviour.domain.BehaviourRecord;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface BehaviourRecordRepository extends JpaRepository<BehaviourRecord, UUID> {

    List<BehaviourRecord> findByLessonId(UUID lessonId);

    /** A student's observations with the lesson they were made in, newest lesson first. */
    @Query("""
            select b as record, l.lessonDate as lessonDate, l.classGroupId as classGroupId
            from BehaviourRecord b join Lesson l on l.id = b.lessonId
            where b.studentId = :studentId
            order by l.lessonDate desc, l.startTime desc
            """)
    List<StudentBehaviourRow> findForStudent(@Param("studentId") UUID studentId);

    interface StudentBehaviourRow {
        BehaviourRecord getRecord();

        LocalDate getLessonDate();

        UUID getClassGroupId();
    }
}
