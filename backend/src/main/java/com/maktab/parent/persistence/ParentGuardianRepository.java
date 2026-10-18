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

    String LINKED_TO_CLASSES = """
            exists (select 1 from StudentParent sp, ClassEnrollment e
                    where sp.id.parentGuardianId = p.id and e.studentId = sp.id.studentId
                      and e.endDate is null and e.classGroupId in :classIds)""";

    Optional<ParentGuardian> findByIdAndOrganisationId(UUID id, UUID organisationId);

    /** A parent the caller may see: with a limited scope, only parents of a child currently in one of its classes. */
    @Query("""
            select p from ParentGuardian p
            where p.id = :id and p.organisationId = :organisationId
              and (:allClasses = true or\s""" + LINKED_TO_CLASSES + ")")
    Optional<ParentGuardian> findInScope(@Param("id") UUID id, @Param("organisationId") UUID organisationId,
            @Param("allClasses") boolean allClasses, @Param("classIds") Collection<UUID> classIds);

    List<ParentGuardian> findByIdInAndOrganisationId(Collection<UUID> ids, UUID organisationId);

    @Query("""
            select p from ParentGuardian p
            where p.organisationId = :organisationId
              and (:allClasses = true or\s""" + LINKED_TO_CLASSES + """
            )
              and (:search is null or p.searchName like :search escape '\\'
                   or p.phone like :search escape '\\'
                   or lower(cast(p.email as string)) like :search escape '\\')
            """)
    Page<ParentGuardian> search(@Param("organisationId") UUID organisationId, @Param("search") String search,
            @Param("allClasses") boolean allClasses, @Param("classIds") Collection<UUID> classIds,
            Pageable pageable);
}
