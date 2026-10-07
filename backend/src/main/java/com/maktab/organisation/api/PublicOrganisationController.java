package com.maktab.organisation.api;

import com.maktab.common.NotFoundException;
import com.maktab.organisation.domain.Organisation;
import com.maktab.organisation.persistence.OrganisationRepository;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The one thing the sign-in screen may know before anyone signs in: the mosque's name. Nothing else about the
 * organisation is public. Maktab runs one organisation for now; with several, the sign-in screen would need to say
 * which one it belongs to.
 */
@RestController
@RequestMapping("/api/public/organisation")
public class PublicOrganisationController {

    private final OrganisationRepository organisations;

    public PublicOrganisationController(OrganisationRepository organisations) {
        this.organisations = organisations;
    }

    @GetMapping
    @PreAuthorize("permitAll()")
    @Transactional(readOnly = true)
    public PublicOrganisationResponse get() {
        return organisations.findById(Organisation.DEFAULT_ID)
                .map(organisation -> new PublicOrganisationResponse(organisation.getName()))
                .orElseThrow(() -> new NotFoundException("Organisation"));
    }

    public record PublicOrganisationResponse(String name) {
    }
}
