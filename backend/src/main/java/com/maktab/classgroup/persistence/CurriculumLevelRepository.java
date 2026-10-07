package com.maktab.classgroup.persistence;

import com.maktab.classgroup.domain.CurriculumLevel;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CurriculumLevelRepository extends JpaRepository<CurriculumLevel, UUID> {

    List<CurriculumLevel> findByOrganisationIdOrderBySortOrderAscNameAsc(UUID organisationId);

    Optional<CurriculumLevel> findByIdAndOrganisationId(UUID id, UUID organisationId);

    List<CurriculumLevel> findByIdIn(Collection<UUID> ids);

    boolean existsByOrganisationIdAndNameIgnoreCase(UUID organisationId, String name);
}
