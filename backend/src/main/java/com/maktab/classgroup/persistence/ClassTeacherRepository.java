package com.maktab.classgroup.persistence;

import com.maktab.classgroup.domain.ClassTeacher;
import java.util.Collection;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ClassTeacherRepository extends JpaRepository<ClassTeacher, UUID> {

    List<ClassTeacher> findByClassGroupIdAndEndDateIsNull(UUID classGroupId);

    List<ClassTeacher> findByClassGroupIdInAndEndDateIsNull(Collection<UUID> classGroupIds);

    @Query("select t.classGroupId from ClassTeacher t where t.teacherUserId = :teacherId and t.endDate is null")
    Set<UUID> findCurrentClassIds(@Param("teacherId") UUID teacherId);
}
