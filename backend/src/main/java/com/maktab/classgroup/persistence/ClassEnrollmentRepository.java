package com.maktab.classgroup.persistence;

import com.maktab.classgroup.domain.ClassEnrollment;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ClassEnrollmentRepository extends JpaRepository<ClassEnrollment, UUID> {

    Optional<ClassEnrollment> findByStudentIdAndEndDateIsNull(UUID studentId);

    List<ClassEnrollment> findByStudentIdInAndEndDateIsNull(Collection<UUID> studentIds);

    List<ClassEnrollment> findByClassGroupIdAndEndDateIsNull(UUID classGroupId);

    @Query("""
            select e from ClassEnrollment e where e.studentId = :studentId
            order by e.startDate desc, e.createdAt desc
            """)
    List<ClassEnrollment> findHistory(@Param("studentId") UUID studentId);

    @Query("""
            select e.classGroupId as classGroupId, count(e) as students from ClassEnrollment e
            where e.classGroupId in :classGroupIds and e.endDate is null
            group by e.classGroupId
            """)
    List<ClassCount> countCurrentStudents(@Param("classGroupIds") Collection<UUID> classGroupIds);

    interface ClassCount {
        UUID getClassGroupId();

        long getStudents();
    }
}
