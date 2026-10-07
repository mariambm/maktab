package com.maktab.curriculum.persistence;

import com.maktab.curriculum.domain.CurriculumWeek;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CurriculumWeekRepository extends JpaRepository<CurriculumWeek, UUID> {

    List<CurriculumWeek> findByCurriculumPeriodIdOrderByWeekNumberAsc(UUID curriculumPeriodId);

    List<CurriculumWeek> findByCurriculumPeriodIdInOrderByWeekNumberAsc(Collection<UUID> curriculumPeriodIds);
}
