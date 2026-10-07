package com.maktab.classgroup.persistence;

import com.maktab.classgroup.domain.ClassGroup;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ClassGroupRepository extends JpaRepository<ClassGroup, UUID> {

    Optional<ClassGroup> findByIdAndOrganisationId(UUID id, UUID organisationId);

    List<ClassGroup> findByIdIn(Collection<UUID> ids);

    boolean existsByOrganisationIdAndNameIgnoreCase(UUID organisationId, String name);

    @Query("""
            select c from ClassGroup c
            where c.id = :id and c.organisationId = :organisationId
              and (:allClasses = true or c.id in :classIds)
            """)
    Optional<ClassGroup> findInScope(@Param("id") UUID id, @Param("organisationId") UUID organisationId,
            @Param("allClasses") boolean allClasses, @Param("classIds") Collection<UUID> classIds);

    @Query("""
            select c from ClassGroup c
            where c.organisationId = :organisationId
              and (:search is null or lower(c.name) like :search escape '\\')
              and (:levelId is null or c.curriculumLevelId = :levelId)
              and (:active is null or c.active = :active)
              and (:allClasses = true or c.id in :classIds)
            """)
    Page<ClassGroup> search(@Param("organisationId") UUID organisationId, @Param("search") String search,
            @Param("levelId") UUID levelId, @Param("active") Boolean active,
            @Param("allClasses") boolean allClasses, @Param("classIds") Collection<UUID> classIds,
            Pageable pageable);
}
