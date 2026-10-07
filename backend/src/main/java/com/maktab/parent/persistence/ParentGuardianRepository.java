package com.maktab.parent.persistence;

import com.maktab.parent.domain.ParentGuardian;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ParentGuardianRepository extends JpaRepository<ParentGuardian, UUID> {

    Optional<ParentGuardian> findByIdAndOrganisationId(UUID id, UUID organisationId);

    List<ParentGuardian> findByIdInAndOrganisationId(Collection<UUID> ids, UUID organisationId);

    @Query("""
            select p from ParentGuardian p
            where p.organisationId = :organisationId
              and (:search is null or p.searchName like :search escape '\\'
                   or p.phone like :search escape '\\'
                   or lower(cast(p.email as string)) like :search escape '\\')
            """)
    Page<ParentGuardian> search(@Param("organisationId") UUID organisationId, @Param("search") String search,
            Pageable pageable);
}
