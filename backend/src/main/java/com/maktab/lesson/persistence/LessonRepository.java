package com.maktab.lesson.persistence;

import com.maktab.lesson.domain.Lesson;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LessonRepository extends JpaRepository<Lesson, UUID> {

    Optional<Lesson> findByClassGroupIdAndLessonDateAndStartTime(UUID classGroupId, LocalDate lessonDate,
            LocalTime startTime);

    List<Lesson> findByClassGroupIdInAndLessonDate(Collection<UUID> classGroupIds, LocalDate lessonDate);

    String IN_ORGANISATION = """
            exists (select 1 from ClassGroup c where c.id = l.classGroupId and c.organisationId = :organisationId)
            """;

    /** One lesson, but only when it belongs to a class of the caller's organisation that the caller may see. */
    @Query("""
            select l from Lesson l
            where l.id = :id and (:allClasses = true or l.classGroupId in :classIds)
              and\s""" + IN_ORGANISATION)
    Optional<Lesson> findInScope(@Param("id") UUID id, @Param("organisationId") UUID organisationId,
            @Param("allClasses") boolean allClasses, @Param("classIds") Collection<UUID> classIds);

    @Query("""
            select l from Lesson l
            where (:allClasses = true or l.classGroupId in :classIds)
              and (:classId is null or l.classGroupId = :classId)
              and (cast(:from as LocalDate) is null or l.lessonDate >= :from)
              and (cast(:to as LocalDate) is null or l.lessonDate <= :to)
              and\s""" + IN_ORGANISATION)
    Page<Lesson> search(@Param("organisationId") UUID organisationId, @Param("classId") UUID classId, @Param("from") LocalDate from, @Param("to") LocalDate to,
            @Param("allClasses") boolean allClasses, @Param("classIds") Collection<UUID> classIds, Pageable pageable);
}
