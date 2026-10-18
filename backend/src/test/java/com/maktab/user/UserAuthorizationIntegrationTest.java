package com.maktab.user;

import static org.hamcrest.Matchers.hasItem;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.maktab.support.IntegrationTest;
import com.maktab.user.domain.Role;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;

class UserAuthorizationIntegrationTest extends IntegrationTest {

    @Test
    void teachersAndAdministratorsCannotManageUsers() throws Exception {
        for (Role role : new Role[] {Role.TEACHER, Role.ADMINISTRATOR}) {
            Session session = loginAs(role);
            mvc.perform(get("/api/users").header("Authorization", session.bearer()))
                    .andExpect(status().isForbidden())
                    .andExpect(jsonPath("$.error").value("FORBIDDEN"));
            mvc.perform(post("/api/users").header("Authorization", session.bearer())
                            .contentType(MediaType.APPLICATION_JSON).content(newUser("x@test.local")))
                    .andExpect(status().isForbidden());
        }
    }

    @Test
    void onlyAdminCanReadTheAuditLog() throws Exception {
        mvc.perform(get("/api/audit-log").header("Authorization", loginAs(Role.TEACHER).bearer()))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/audit-log").header("Authorization", loginAs(Role.ADMINISTRATOR).bearer()))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/audit-log").header("Authorization", loginAs(Role.ADMIN).bearer()))
                .andExpect(status().isOk());
    }

    @Test
    void teachersHaveNoPaymentAccessByDefault() throws Exception {
        mvc.perform(get("/api/me").header("Authorization", loginAs(Role.TEACHER).bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.permissions", not(hasItem("PAYMENT_READ"))))
                .andExpect(jsonPath("$.permissions", not(hasItem("PAYMENT_WRITE"))));
        mvc.perform(get("/api/me").header("Authorization", loginAs(Role.ADMINISTRATOR).bearer()))
                .andExpect(jsonPath("$.permissions", hasItem("PAYMENT_READ")))
                .andExpect(jsonPath("$.permissions", not(hasItem("USER_MANAGE"))));
    }

    @Test
    void adminCanGrantPaymentReadToOneTeacherAndItAppliesImmediately() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);

        mvc.perform(put("/api/users/{id}/permissions", teacher.user().id()).header("Authorization", admin.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"permissions\":[\"PAYMENT_READ\"]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.grantedPermissions[0]").value("PAYMENT_READ"));

        mvc.perform(get("/api/me").header("Authorization", teacher.bearer()))
                .andExpect(jsonPath("$.permissions", hasItem("PAYMENT_READ")));
    }

    @Test
    void adminCreatesAUserWithAOneTimePassword() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        String email = "new-" + UUID.randomUUID().toString().substring(0, 8) + "@test.local";

        String body = mvc.perform(post("/api/users").header("Authorization", admin.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content(newUser(email)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.user.email").value(email))
                .andExpect(jsonPath("$.user.mustChangePassword").value(true))
                .andExpect(jsonPath("$.temporaryPassword").isNotEmpty())
                .andReturn().getResponse().getContentAsString();
        String temporaryPassword = JsonPath.read(body, "$.temporaryPassword");
        String id = JsonPath.read(body, "$.user.id");

        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json(email, temporaryPassword)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.mustChangePassword").value(true));

        String audit = mvc.perform(get("/api/audit-log").param("entityId", id)
                        .header("Authorization", admin.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.items[*].action", hasItem("USER_CREATED")))
                .andReturn().getResponse().getContentAsString();
        org.assertj.core.api.Assertions.assertThat(audit).doesNotContain(temporaryPassword);

        mvc.perform(post("/api/users").header("Authorization", admin.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content(newUser(email.toUpperCase())))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.error").value("CONFLICT"));
    }

    @Test
    void createUserValidatesInput() throws Exception {
        mvc.perform(post("/api/users").header("Authorization", loginAs(Role.ADMIN).bearer())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"not-an-email\",\"firstName\":\"\",\"lastName\":\"X\",\"roles\":[]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.email").value("Enter a valid email address"))
                .andExpect(jsonPath("$.fieldErrors.firstName").value("First name is required"))
                .andExpect(jsonPath("$.fieldErrors.roles").value("Choose at least one role"));
    }

    @Test
    void adminCannotLockThemselvesOut() throws Exception {
        Session admin = loginAs(Role.ADMIN);

        mvc.perform(put("/api/users/{id}/roles", admin.user().id()).header("Authorization", admin.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"roles\":[\"TEACHER\"]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.roles").value("You cannot remove your own ADMIN role"));
        mvc.perform(patch("/api/users/{id}/status", admin.user().id()).header("Authorization", admin.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"active\":false}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void deactivatingAUserEndsTheirSessions() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);

        mvc.perform(patch("/api/users/{id}/status", teacher.user().id()).header("Authorization", admin.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"active\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.active").value(false));

        mvc.perform(get("/api/me").header("Authorization", teacher.bearer())).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"" + teacher.refreshToken() + "\"}"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void unknownOrMalformedIdsReturnStructuredErrors() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        mvc.perform(get("/api/users/{id}", UUID.randomUUID()).header("Authorization", admin.bearer()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("NOT_FOUND"));
        mvc.perform(get("/api/users/not-a-uuid").header("Authorization", admin.bearer()))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("VALIDATION_ERROR"));
    }

    @Test
    void userListSupportsSearchAndRoleFilter() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);

        mvc.perform(get("/api/users").param("search", teacher.user().email()).param("role", "TEACHER")
                        .header("Authorization", admin.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalItems").value(1))
                .andExpect(jsonPath("$.items[0].id").value(teacher.user().id().toString()));
    }

    @Test
    void aTemporaryPasswordOnlyLetsTheUserSetTheirOwnPassword() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        String email = "temp-" + UUID.randomUUID().toString().substring(0, 8) + "@test.local";
        String created = mvc.perform(post("/api/users").header("Authorization", admin.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content(newUser(email)))
                .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        String temporaryPassword = JsonPath.read(created, "$.temporaryPassword");
        String login = mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json(email, temporaryPassword)))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        String bearer = "Bearer " + JsonPath.read(login, "$.accessToken");

        // Calling the API directly, past the app's change-password screen, gets nothing.
        mvc.perform(get("/api/classes").header("Authorization", bearer)).andExpect(status().isForbidden());
        mvc.perform(get("/api/me").header("Authorization", bearer))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mustChangePassword").value(true));

        mvc.perform(put("/api/me/password").header("Authorization", bearer).contentType(MediaType.APPLICATION_JSON)
                        .content("{\"currentPassword\":\"" + temporaryPassword
                                + "\",\"newPassword\":\"A-new-password-1\"}"))
                .andExpect(status().isNoContent());
        mvc.perform(get("/api/classes").header("Authorization", bearer)).andExpect(status().isOk());
    }

    @Test
    void aPasswordResetIssuesATemporaryPasswordAndEndsTheUsersSessions() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session teacher = loginAs(Role.TEACHER);

        String body = mvc.perform(post("/api/users/{id}/password-reset", teacher.user().id())
                        .header("Authorization", admin.bearer()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.mustChangePassword").value(true))
                .andExpect(jsonPath("$.temporaryPassword").isNotEmpty())
                .andReturn().getResponse().getContentAsString();

        mvc.perform(post("/api/auth/refresh").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"refreshToken\":\"" + teacher.refreshToken() + "\"}"))
                .andExpect(status().isUnauthorized());
        mvc.perform(post("/api/auth/login").contentType(MediaType.APPLICATION_JSON)
                        .content(json(teacher.user().email(), JsonPath.read(body, "$.temporaryPassword"))))
                .andExpect(status().isOk());
    }

    @Test
    void aUserManagerWhoIsNotAdminCannotHandOutAdminRights() throws Exception {
        Session admin = loginAs(Role.ADMIN);
        Session manager = loginAs(Role.ADMINISTRATOR);
        Session teacher = loginAs(Role.TEACHER);
        mvc.perform(put("/api/users/{id}/permissions", manager.user().id()).header("Authorization", admin.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"permissions\":[\"USER_MANAGE\"]}"))
                .andExpect(status().isOk());

        mvc.perform(put("/api/users/{id}/roles", manager.user().id()).header("Authorization", manager.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"roles\":[\"ADMIN\"]}"))
                .andExpect(status().isForbidden());
        mvc.perform(put("/api/users/{id}/permissions", teacher.user().id()).header("Authorization", manager.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"permissions\":[\"AUDIT_READ\"]}"))
                .andExpect(status().isForbidden());
        mvc.perform(post("/api/users/{id}/password-reset", admin.user().id())
                        .header("Authorization", manager.bearer()))
                .andExpect(status().isForbidden());

        // Everyday rights are still theirs to give.
        mvc.perform(put("/api/users/{id}/permissions", teacher.user().id()).header("Authorization", manager.bearer())
                        .contentType(MediaType.APPLICATION_JSON).content("{\"permissions\":[\"PAYMENT_READ\"]}"))
                .andExpect(status().isOk());
    }

    private static String newUser(String email) {
        return "{\"email\":\"" + email + "\",\"firstName\":\"Sara\",\"lastName\":\"Ahmed\",\"roles\":[\"TEACHER\"]}";
    }
}
