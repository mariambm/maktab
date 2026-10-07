package com.maktab.student.domain;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Table;
import java.util.UUID;

/** Links a student to a parent/guardian. A parent can have several children and a child several parents. */
@Entity
@Table(name = "student_parent")
public class StudentParent {

    @EmbeddedId
    private StudentParentId id;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ParentRelationship relationship;

    @Column(name = "is_primary_contact", nullable = false)
    private boolean primaryContact;

    protected StudentParent() {
    }

    public StudentParent(UUID studentId, UUID parentGuardianId, ParentRelationship relationship,
            boolean primaryContact) {
        this.id = new StudentParentId(studentId, parentGuardianId);
        this.relationship = relationship;
        this.primaryContact = primaryContact;
    }

    public UUID getStudentId() {
        return id.getStudentId();
    }

    public UUID getParentGuardianId() {
        return id.getParentGuardianId();
    }

    public ParentRelationship getRelationship() {
        return relationship;
    }

    public boolean isPrimaryContact() {
        return primaryContact;
    }
}
