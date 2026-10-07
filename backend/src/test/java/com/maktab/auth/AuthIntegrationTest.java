package com.maktab.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.maktab.audit.persistence.AuditLogRepository;
import com.maktab.support.IntegrationTest;
import com.maktab.support.TestUsers;
import com.maktab.user.domain.Role;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;

class AuthIntegrationTest extends IntegrationTest {

    @Autowired
    AuditLogRepository auditLog;

    @Test
    void loginReturnsTokensAndTheUsersRolesAndPermissions() throws Exception {
        TestUsers.TestUser teacher = testUsers.create(Role.TEACHER);

        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json(teacher.email(), TestUsers.PASSWORD)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.refreshToken").isNotEmpty())
                .andExpect(jsonPath("$.user.email").value(teacher.email()))
                .andExpect(jsonPath("$.user.roles[0]").value("TEACHER"))
                .andExpect(jsonPath("$.user.passwordHash").doesNotExist());
    }

    @Test
    void wrongPasswordAndUnknownEmailGetTheSameGenericAnswer() throws Exception {
        TestUsers.TestUser user = testUsers.create(Role.TEACHER);

        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json(user.email(), "wrong-password")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("UNAUTHENTICATED"))
                .andExpect(jsonPath("$.message").value("Invalid email or password"))
                .andExpect(jsonPath("$.trace").doesNotExist());

        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json("nobody@test.local", "wrong-password")))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid email or password"));
    }

    @Test
    void failedLoginIsAuditedWithoutThePassword() throws Exception {
        TestUsers.TestUser user = testUsers.create(Role.TEACHER);

        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content(json(user.email(), "a-secret-guess")));

        var entries = auditLog.search(com.maktab.organisation.domain.Organisation.DEFAULT_ID, "User", user.id(),
                null, null, null, PageRequest.of(0, 10)).getContent();
        assertThat(entries).extracting("action").contains("LOGIN_FAILED");
        assertThat(entries).allSatisfy(entry -> {
            assertThat(String.valueOf(entry.getNewValue())).doesNotContain("a-secret-guess");
            assertThat(String.valueOf(entry.getOldValue())).doesNotContain("a-secret-guess");
        });
    }

    @Test
    void inactiveUserCannotLogIn() throws Exception {
        TestUsers.TestUser user = testUsers.create(Role.TEACHER);
        testUsers.deactivate(user.id());

        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json(user.email(), TestUsers.PASSWORD)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid email or password"));
    }

    @Test
    void accountIsLockedAfterFiveFailedAttempts() throws Exception {
        TestUsers.TestUser user = testUsers.create(Role.TEACHER);
        for (int i = 0; i < 5; i++) {
            mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                            .content(json(user.email(), "wrong-password")))
                    .andExpect(status().isUnauthorized());
        }

        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json(user.email(), TestUsers.PASSWORD)))
                .andExpect(status().isTooManyRequests())
                .andExpect(jsonPath("$.error").value("TOO_MANY_REQUESTS"));
    }

    @Test
    void loginValidationUsesTheStandardErrorFormat() throws Exception {
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"\",\"password\":\"\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.status").value(400))
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.message").value("Validation failed"))
                .andExpect(jsonPath("$.timestamp").isNotEmpty())
                .andExpect(jsonPath("$.fieldErrors.email").isNotEmpty())
                .andExpect(jsonPath("$.fieldErrors.password").value("Password is required"));
    }

    @Test
    void malformedJsonIsRejectedWithoutDetails() throws Exception {
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON).content("{not json"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("MALFORMED_REQUEST"))
                .andExpect(jsonPath("$.message").value("The request could not be read"));
    }

    @Test
    void protectedEndpointsRequireAToken() throws Exception {
        mvc.perform(get("/api/me"))
                .andExpect(status().isUnauthorized())
                .andExpect(header().exists("X-Correlation-Id"))
                .andExpect(jsonPath("$.error").value("UNAUTHENTICATED"));
    }

    @Test
    void tamperedTokenIsRejected() throws Exception {
        Session session = loginAs(Role.TEACHER);
        String tampered = session.accessToken().substring(0, session.accessToken().length() - 2) + "xx";

        mvc.perform(get("/api/me").header("Authorization", "Bearer " + tampered))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("UNAUTHENTICATED"));
    }

    @Test
    void deactivatedUsersAccessTokenStopsWorkingImmediately() throws Exception {
        Session session = loginAs(Role.TEACHER);
        mvc.perform(get("/api/me").header("Authorization", session.bearer())).andExpect(status().isOk());

        testUsers.deactivate(session.user().id());

        mvc.perform(get("/api/me").header("Authorization", session.bearer()))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void refreshRotatesTheTokenAndReuseRevokesTheWholeSession() throws Exception {
        Session session = loginAs(Role.TEACHER);

        String body = mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(refresh(session.refreshToken())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andReturn().getResponse().getContentAsString();
        String rotated = JsonPath.read(body, "$.refreshToken");
        assertThat(rotated).isNotEqualTo(session.refreshToken());

        // The old token is presented again: treat it as stolen and end the session.
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(refresh(session.refreshToken())))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(refresh(rotated)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void logoutRevokesTheRefreshToken() throws Exception {
        Session session = loginAs(Role.TEACHER);

        mvc.perform(post("/api/auth/logout").contentType(MediaType.APPLICATION_JSON)
                        .content(refresh(session.refreshToken())))
                .andExpect(status().isNoContent());
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(refresh(session.refreshToken())))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void changingPasswordRequiresTheCurrentPasswordAndEndsOtherSessions() throws Exception {
        Session session = loginAs(Role.TEACHER);

        mvc.perform(put("/api/me/password").header("Authorization", session.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"currentPassword\":\"wrong\",\"newPassword\":\"A-new-password-1\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.currentPassword").value("Current password is incorrect"));

        mvc.perform(put("/api/me/password").header("Authorization", session.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"currentPassword\":\"" + TestUsers.PASSWORD
                                + "\",\"newPassword\":\"short\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.newPassword").exists());

        mvc.perform(put("/api/me/password").header("Authorization", session.bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"currentPassword\":\"" + TestUsers.PASSWORD
                                + "\",\"newPassword\":\"A-new-password-1\"}"))
                .andExpect(status().isNoContent());

        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content(refresh(session.refreshToken())))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json(session.user().email(), "A-new-password-1")))
                .andExpect(status().isOk());
    }

    private static String refresh(String token) {
        return "{\"refreshToken\":\"" + token + "\"}";
    }
}
