package com.maktab.support;

import com.maktab.organisation.domain.Organisation;
import com.maktab.user.domain.Role;
import com.maktab.user.domain.User;
import com.maktab.user.persistence.UserRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** Creates users with unique emails so tests never depend on each other. */
@Component
public class TestUsers {

    public static final String PASSWORD = "Correct-Horse-42";

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private String cachedHash;

    public TestUsers(UserRepository users, PasswordEncoder passwordEncoder) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional
    public TestUser create(Role... roles) {
        if (cachedHash == null) {
            cachedHash = passwordEncoder.encode(PASSWORD);
        }
        String email = "user-" + UUID.randomUUID().toString().substring(0, 8) + "@test.local";
        User user = users.save(new User(Organisation.DEFAULT_ID, email, cachedHash, "Test", "User", List.of(roles)));
        return new TestUser(user.getId(), email);
    }

    @Transactional
    public void deactivate(UUID id) {
        users.findById(id).orElseThrow().setActive(false);
    }

    public record TestUser(UUID id, String email) {
    }
}
