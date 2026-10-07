package com.maktab.curriculum.persistence;

import com.maktab.curriculum.domain.LessonTopic;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface LessonTopicRepository extends JpaRepository<LessonTopic, UUID> {

    List<LessonTopic> findByCurriculumWeekIdInOrderBySortOrderAscTitleAsc(Collection<UUID> curriculumWeekIds);

    void deleteByCurriculumWeekIdIn(Collection<UUID> curriculumWeekIds);

    /** The topics of {@code topicIds} that belong to the given period, so a lesson cannot cover another level's topics. */
    @Query("""
            select t from LessonTopic t
            where t.id in :topicIds
              and t.curriculumWeekId in (select w.id from CurriculumWeek w where w.curriculumPeriodId = :periodId)
            """)
    List<LessonTopic> findInPeriod(@Param("topicIds") Collection<UUID> topicIds, @Param("periodId") UUID periodId);

    List<LessonTopic> findByIdIn(Collection<UUID> ids);
}
