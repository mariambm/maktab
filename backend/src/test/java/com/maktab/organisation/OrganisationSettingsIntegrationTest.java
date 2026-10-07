package com.maktab.organisation;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

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

    @Test
    void theSignInScreenCanShowTheMosquesNameAndNothingElse() throws Exception {
        mvc.perform(get("/api/public/organisation"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Jamiyat Tabligh UL Islam"))
                .andExpect(jsonPath("$.currency").doesNotExist())
                .andExpect(jsonPath("$.id").doesNotExist());
    }
}
