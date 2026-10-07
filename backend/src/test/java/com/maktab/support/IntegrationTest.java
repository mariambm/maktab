package com.maktab.support;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.maktab.user.domain.Role;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Full application against a real PostgreSQL (Testcontainers) with Flyway migrations applied, so tests exercise the
 * same schema, security filter chain and error handling as production.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Import({TestcontainersConfig.class, TestUsers.class})
public abstract class IntegrationTest {

    @Autowired
    protected MockMvc mvc;

    @Autowired
    protected TestUsers testUsers;

    protected Session loginAs(Role... roles) throws Exception {
        TestUsers.TestUser user = testUsers.create(roles);
        return login(user);
    }

    protected Session login(TestUsers.TestUser user) throws Exception {
        String body = mvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(json(user.email(), TestUsers.PASSWORD)))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return new Session(user, JsonPath.read(body, "$.accessToken"), JsonPath.read(body, "$.refreshToken"));
    }

    protected static String json(String email, String password) {
        return "{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}";
    }

    public record Session(TestUsers.TestUser user, String accessToken, String refreshToken) {

        public String bearer() {
            return "Bearer " + accessToken;
        }
    }
}
