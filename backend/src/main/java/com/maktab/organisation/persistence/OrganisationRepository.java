package com.maktab.organisation.persistence;

import com.maktab.organisation.domain.Organisation;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrganisationRepository extends JpaRepository<Organisation, UUID> {
}
