package com.maktab.progress.persistence;

import com.maktab.progress.domain.StudentTarget;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StudentTargetRepository extends JpaRepository<StudentTarget, UUID> {

    List<StudentTarget> findByStudentId(UUID studentId);

    List<StudentTarget> findByCurriculumPeriodIdAndStudentIdIn(UUID periodId, Collection<UUID> studentIds);
}
