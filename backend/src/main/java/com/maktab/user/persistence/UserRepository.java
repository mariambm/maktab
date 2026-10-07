package com.maktab.user.persistence;

import com.maktab.user.domain.Role;
import com.maktab.user.domain.User;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<User, UUID> {

    Optional<User> findByOrganisationIdAndEmail(UUID organisationId, String email);

    Optional<User> findByIdAndOrganisationId(UUID id, UUID organisationId);

    boolean existsByOrganisationIdAndEmail(UUID organisationId, String email);

    @Query("""
            select distinct u from User u left join u.roles r
            where u.organisationId = :organisationId
              and (:search is null
                   or lower(u.firstName) like lower(concat('%', cast(:search as string), '%'))
                   or lower(u.lastName) like lower(concat('%', cast(:search as string), '%'))
                   or lower(cast(u.email as string)) like lower(concat('%', cast(:search as string), '%')))
              and (:role is null or r = :role)
              and (:active is null or u.active = :active)
            """)
    Page<User> search(@Param("organisationId") UUID organisationId, @Param("search") String search,
            @Param("role") Role role, @Param("active") Boolean active, Pageable pageable);
}
