package com.maktab.lesson.persistence;

import com.maktab.lesson.domain.LessonTopicCovered;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LessonTopicCoveredRepository extends JpaRepository<LessonTopicCovered, LessonTopicCovered.Id> {

    List<LessonTopicCovered> findByIdLessonId(UUID lessonId);

    List<LessonTopicCovered> findByIdLessonIdIn(Collection<UUID> lessonIds);

    void deleteByIdLessonId(UUID lessonId);
}
