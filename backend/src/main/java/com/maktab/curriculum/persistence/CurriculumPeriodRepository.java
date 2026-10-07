package com.maktab.curriculum.persistence;

import com.maktab.curriculum.domain.CurriculumPeriod;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CurriculumPeriodRepository extends JpaRepository<CurriculumPeriod, UUID> {

    List<CurriculumPeriod> findByCurriculumLevelIdOrderByNumberAsc(UUID curriculumLevelId);

    boolean existsByCurriculumLevelIdAndNumber(UUID curriculumLevelId, short number);

    /** The period of this level that contains {@code date}; periods of one level never overlap. */
    @Query("""
            select p from CurriculumPeriod p
            where p.curriculumLevelId = :levelId and :date between p.startDate and p.endDate
            """)
    Optional<CurriculumPeriod> findOnDate(@Param("levelId") UUID levelId, @Param("date") LocalDate date);

    @Query("""
            select p from CurriculumPeriod p
            where p.curriculumLevelId = :levelId and p.startDate <= :end and p.endDate >= :start
              and (:excludeId is null or p.id <> :excludeId)
            """)
    List<CurriculumPeriod> findOverlapping(@Param("levelId") UUID levelId, @Param("start") LocalDate start,
            @Param("end") LocalDate end, @Param("excludeId") UUID excludeId);

    List<CurriculumPeriod> findByIdIn(Collection<UUID> ids);
}
