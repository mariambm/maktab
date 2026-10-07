package com.maktab.dev;

import com.maktab.organisation.domain.Organisation;
import com.maktab.user.domain.Role;
import com.maktab.user.domain.User;
import com.maktab.user.persistence.UserRepository;
import java.util.List;
import java.util.Set;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Development-only fake accounts. Runs only with the {@code dev} profile and only on an empty user table. School data
 * (classes, students, parents) is seeded afterwards by {@link DevSchoolDataSeeder}.
 */
@Component
@Profile("dev")
@Order(1)
public class DevDataSeeder implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DevDataSeeder.class);

    private record SeedUser(String email, String firstName, String lastName, Set<Role> roles) {
    }

    private static final List<SeedUser> USERS = List.of(
            new SeedUser("admin@maktab.local", "Yusuf", "Rahman", Set.of(Role.ADMIN)),
            new SeedUser("administrator1@maktab.local", "Khadija", "Bakker", Set.of(Role.ADMINISTRATOR)),
            new SeedUser("administrator2@maktab.local", "Ibrahim", "de Vries", Set.of(Role.ADMINISTRATOR)),
            new SeedUser("teacher1@maktab.local", "Aisha", "Yilmaz", Set.of(Role.TEACHER)),
            new SeedUser("teacher2@maktab.local", "Omar", "El Amrani", Set.of(Role.TEACHER)),
            new SeedUser("teacher3@maktab.local", "Maryam", "Hassan", Set.of(Role.TEACHER)),
            new SeedUser("teacher4@maktab.local", "Bilal", "Jansen", Set.of(Role.TEACHER)));

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final String seedPassword;

    public DevDataSeeder(UserRepository users, PasswordEncoder passwordEncoder,
            @Value("${maktab.dev.seed-password}") String seedPassword) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.seedPassword = seedPassword;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        if (users.count() > 0) {
            return;
        }
        String hash = passwordEncoder.encode(seedPassword);
        USERS.forEach(seed -> users.save(new User(Organisation.DEFAULT_ID, seed.email(), hash, seed.firstName(),
                seed.lastName(), seed.roles())));
        log.info("Seeded {} development users (password from DEV_SEED_PASSWORD)", USERS.size());
    }
}
