package com.maktab.student.persistence;

import com.maktab.student.domain.Student;
import com.maktab.student.domain.StudentStatus;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

/**
 * Student queries take the caller's access scope: unless {@code allClasses} is set, a student is only found when
 * their current enrolment is in one of {@code classIds}.
 */
public interface StudentRepository extends JpaRepository<Student, UUID> {

    List<Student> findByIdIn(Collection<UUID> ids);

    @Query("""
            select s from Student s
            where s.id = :id and s.organisationId = :organisationId
              and (:allClasses = true or exists (
                    select 1 from ClassEnrollment e
                    where e.studentId = s.id and e.endDate is null and e.classGroupId in :classIds))
            """)
    Optional<Student> findInScope(@Param("id") UUID id, @Param("organisationId") UUID organisationId,
            @Param("allClasses") boolean allClasses, @Param("classIds") Collection<UUID> classIds);

    @Query("""
            select s from Student s
            where s.organisationId = :organisationId
              and (:search is null or s.searchName like :search escape '\\')
              and (:status is null or s.status = :status)
              and (:classId is null or exists (
                    select 1 from ClassEnrollment e
                    where e.studentId = s.id and e.endDate is null and e.classGroupId = :classId))
              and (:allClasses = true or exists (
                    select 1 from ClassEnrollment e
                    where e.studentId = s.id and e.endDate is null and e.classGroupId in :classIds))
            """)
    Page<Student> search(@Param("organisationId") UUID organisationId, @Param("search") String search,
            @Param("status") StudentStatus status, @Param("classId") UUID classId,
            @Param("allClasses") boolean allClasses, @Param("classIds") Collection<UUID> classIds,
            Pageable pageable);
}
