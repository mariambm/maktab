package com.maktab.behaviour.domain;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.EnumSet;
import java.util.Set;
import java.util.UUID;

/** What a teacher observed about one student in one lesson. An observation of that day, never a label. */
@Entity
@Table(name = "behaviour_record")
public class BehaviourRecord {

    @Id
    private UUID id;

    @Column(name = "lesson_id", nullable = false, updatable = false)
    private UUID lessonId;

    @Column(name = "student_id", nullable = false, updatable = false)
    private UUID studentId;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "behaviour_record_item", joinColumns = @JoinColumn(name = "behaviour_record_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "behaviour", nullable = false)
    private Set<Behaviour> behaviours = EnumSet.noneOf(Behaviour.class);

    @Column
    private String note;

    @Column(name = "recorded_by", nullable = false)
    private UUID recordedBy;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private long version;

    protected BehaviourRecord() {
    }

    public BehaviourRecord(UUID lessonId, UUID studentId) {
        this.id = UUID.randomUUID();
        this.lessonId = lessonId;
        this.studentId = studentId;
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

    public void record(Set<Behaviour> behaviours, String note, UUID recordedBy) {
        this.behaviours.clear();
        this.behaviours.addAll(behaviours);
        this.note = note;
        this.recordedBy = recordedBy;
        // A collection change alone does not touch the row; keep updated_at and the version honest.
        this.updatedAt = Instant.now();
    }

    public UUID getId() {
        return id;
    }

    public UUID getLessonId() {
        return lessonId;
    }

    public UUID getStudentId() {
        return studentId;
    }

    public Set<Behaviour> getBehaviours() {
        return behaviours;
    }

    public String getNote() {
        return note;
    }
}
