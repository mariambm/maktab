package com.maktab.auth.application;

import com.maktab.user.domain.User;
import com.maktab.user.persistence.UserRepository;
import java.util.UUID;
import org.springframework.core.convert.converter.Converter;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Resolves a validated JWT into the current user. Loading the user on every request means a deactivated account or
 * a revoked permission takes effect immediately, not when the token expires.
 */
@Component
public class CurrentUserJwtConverter implements Converter<Jwt, AbstractAuthenticationToken> {

    private final UserRepository users;

    public CurrentUserJwtConverter(UserRepository users) {
        this.users = users;
    }

    @Override
    @Transactional(readOnly = true)
    public AbstractAuthenticationToken convert(Jwt jwt) {
        UUID userId;
        try {
            userId = UUID.fromString(jwt.getSubject());
        } catch (IllegalArgumentException | NullPointerException e) {
            throw new DisabledException("Invalid subject");
        }
        User user = users.findById(userId)
                .filter(User::isActive)
                .orElseThrow(() -> new DisabledException("User not found or inactive"));
        return new CurrentUserAuthentication(CurrentUser.of(user), jwt);
    }
}
