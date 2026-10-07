package com.maktab.student.persistence;

import com.maktab.student.domain.StudentParent;
import com.maktab.student.domain.StudentParentId;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface StudentParentRepository extends JpaRepository<StudentParent, StudentParentId> {

    List<StudentParent> findByIdStudentId(UUID studentId);

    List<StudentParent> findByIdParentGuardianIdIn(Collection<UUID> parentGuardianIds);

    @Modifying(flushAutomatically = true, clearAutomatically = false)
    @Query("delete from StudentParent l where l.id.studentId = :studentId")
    void deleteByStudentId(@Param("studentId") UUID studentId);
}
