package com.maktab.progress.persistence;

import com.maktab.progress.domain.ProgressScaleLevel;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProgressScaleLevelRepository extends JpaRepository<ProgressScaleLevel, ProgressScaleLevel.Key> {

    List<ProgressScaleLevel> findByOrganisationIdOrderByScore(UUID organisationId);
}
