package com.maktab.organisation.application;

import com.maktab.organisation.domain.Organisation;
import com.maktab.organisation.persistence.OrganisationRepository;
import java.time.Clock;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** "Today" in the organisation's own time zone, so a late-evening change in Amsterdam is not dated tomorrow. */
@Service
public class OrganisationCalendar {

    private final OrganisationRepository organisations;
    private final Clock clock;

    public OrganisationCalendar(OrganisationRepository organisations, Clock clock) {
        this.organisations = organisations;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public LocalDate today(UUID organisationId) {
        ZoneId zone = organisations.findById(organisationId)
                .map(Organisation::getTimeZone)
                .map(ZoneId::of)
                .orElse(ZoneId.of("Europe/Amsterdam"));
        return LocalDate.now(clock.withZone(zone));
    }
}
