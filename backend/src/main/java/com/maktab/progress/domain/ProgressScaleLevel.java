package com.maktab.progress.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;
import java.io.Serializable;
import java.math.BigDecimal;
import java.util.UUID;

/** One step of the organisation's progress scale, such as 3.5 = Almost Good. */
@Entity
@Table(name = "progress_scale_level")
@IdClass(ProgressScaleLevel.Key.class)
public class ProgressScaleLevel {

    @Id
    @Column(name = "organisation_id")
    private UUID organisationId;

    @Id
    @Column(name = "score")
    private BigDecimal score;

    @Column(nullable = false)
    private String label;

    protected ProgressScaleLevel() {
    }

    public UUID getOrganisationId() {
        return organisationId;
    }

    public BigDecimal getScore() {
        return score;
    }

    public String getLabel() {
        return label;
    }

    /** The composite key: one label per score per organisation. */
    public record Key(UUID organisationId, BigDecimal score) implements Serializable {
    }
}
