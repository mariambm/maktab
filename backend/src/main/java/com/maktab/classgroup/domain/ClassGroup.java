package com.maktab.classgroup.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

/** A class, for example "Saturday Qaida B". Classes are deactivated, never deleted, so their history stays. */
@Entity
@Table(name = "class_group")
public class ClassGroup {

    @Id
    private UUID id;

    @Column(name = "organisation_id", nullable = false, updatable = false)
    private UUID organisationId;

    @Column(name = "curriculum_level_id", nullable = false)
    private UUID curriculumLevelId;

    @Column(nullable = false)
    private String name;

    private String room;

    @Column(nullable = false)
    private boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private long version;

    protected ClassGroup() {
    }

    public ClassGroup(UUID organisationId, UUID curriculumLevelId, String name, String room) {
        this.id = UUID.randomUUID();
        this.organisationId = organisationId;
        this.curriculumLevelId = curriculumLevelId;
        this.name = name;
        this.room = room;
    }

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public void update(UUID curriculumLevelId, String name, String room, boolean active) {
        this.curriculumLevelId = curriculumLevelId;
        this.name = name;
        this.room = room;
        this.active = active;
    }

    public UUID getId() {
        return id;
    }

    public UUID getOrganisationId() {
        return organisationId;
    }

    public UUID getCurriculumLevelId() {
        return curriculumLevelId;
    }

    public String getName() {
        return name;
    }

    public String getRoom() {
        return room;
    }

    public boolean isActive() {
        return active;
    }
}
