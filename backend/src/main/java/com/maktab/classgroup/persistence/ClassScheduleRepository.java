package com.maktab.classgroup.persistence;

import com.maktab.classgroup.domain.ClassSchedule;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ClassScheduleRepository extends JpaRepository<ClassSchedule, UUID> {

    List<ClassSchedule> findByClassGroupIdInOrderByWeekdayAscStartTimeAsc(Collection<UUID> classGroupIds);

    @Modifying(flushAutomatically = true, clearAutomatically = false)
    @Query("delete from ClassSchedule s where s.classGroupId = :classGroupId")
    void deleteByClassGroupId(@Param("classGroupId") UUID classGroupId);
}
