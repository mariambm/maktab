package com.maktab.student.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;
import java.util.UUID;

@Embeddable
public class StudentParentId implements Serializable {

    @Column(name = "student_id", nullable = false)
    private UUID studentId;

    @Column(name = "parent_guardian_id", nullable = false)
    private UUID parentGuardianId;

    protected StudentParentId() {
    }

    public StudentParentId(UUID studentId, UUID parentGuardianId) {
        this.studentId = studentId;
        this.parentGuardianId = parentGuardianId;
    }

    public UUID getStudentId() {
        return studentId;
    }

    public UUID getParentGuardianId() {
        return parentGuardianId;
    }

    @Override
    public boolean equals(Object other) {
        return other instanceof StudentParentId that
                && studentId.equals(that.studentId) && parentGuardianId.equals(that.parentGuardianId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(studentId, parentGuardianId);
    }
}
