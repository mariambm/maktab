package com.maktab.progress.application;

import com.maktab.progress.domain.ProgressScaleLevel;
import com.maktab.progress.persistence.ProgressScaleLevelRepository;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** The organisation's progress scale: which scores exist and what they are called. */
@Component
public class ProgressScale {

    private final ProgressScaleLevelRepository levels;

    public ProgressScale(ProgressScaleLevelRepository levels) {
        this.levels = levels;
    }

    @Transactional(readOnly = true)
    public List<ProgressScaleLevel> levels(UUID organisationId) {
        return levels.findByOrganisationIdOrderByScore(organisationId);
    }

    /** Looks scores up by value, so 4, 4.0 and 4.00 are the same score. */
    @Transactional(readOnly = true)
    public Lookup lookup(UUID organisationId) {
        return new Lookup(levels(organisationId).stream()
                .collect(Collectors.toMap(level -> level.getScore().stripTrailingZeros(), Function.identity())));
    }

    public record Lookup(Map<BigDecimal, ProgressScaleLevel> byScore) {

        public Optional<ProgressScaleLevel> find(BigDecimal score) {
            return score == null ? Optional.empty() : Optional.ofNullable(byScore.get(score.stripTrailingZeros()));
        }

        public String labelOf(BigDecimal score) {
            return find(score).map(ProgressScaleLevel::getLabel).orElse(null);
        }
    }
}
