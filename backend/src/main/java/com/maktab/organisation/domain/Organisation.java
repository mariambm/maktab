package com.maktab.organisation.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "organisation")
public class Organisation {

    /** The single organisation seeded by V1. Multi-organisation support is a future feature. */
    public static final UUID DEFAULT_ID = UUID.fromString("00000000-0000-0000-0000-000000000001");

    @Id
    private UUID id;

    @Column(nullable = false)
    private String name;

    @Column(name = "time_zone", nullable = false)
    private String timeZone;

    @Column(nullable = false, length = 3)
    private String currency;

    @Column(name = "attendance_threshold_pct", nullable = false)
    private short attendanceThresholdPct;

    @Column(name = "created_at", nullable = false, updatable = false, insertable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false, insertable = false)
    private Instant updatedAt;

    @Version
    private long version;

    protected Organisation() {
    }

    public UUID getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public String getTimeZone() {
        return timeZone;
    }

    public String getCurrency() {
        return currency;
    }

    public short getAttendanceThresholdPct() {
        return attendanceThresholdPct;
    }
}
