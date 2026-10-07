package com.maktab.organisation;

import static org.assertj.core.api.Assertions.assertThat;

import com.maktab.organisation.domain.Organisation;
import com.maktab.organisation.persistence.OrganisationRepository;
import com.maktab.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

class OrganisationSettingsIntegrationTest extends IntegrationTest {

    @Autowired
    private OrganisationRepository organisations;

    @Test
    void theMosqueIsSetUpInPoundsAndUkTime() {
        Organisation mosque = organisations.findById(Organisation.DEFAULT_ID).orElseThrow();

        assertThat(mosque.getName()).isEqualTo("Jamiyat Tabligh UL Islam");
        assertThat(mosque.getCurrency()).isEqualTo("GBP");
        assertThat(mosque.getTimeZone()).isEqualTo("Europe/London");
    }
}
