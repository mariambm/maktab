package com.maktab.auth.application;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import org.springframework.security.authentication.AbstractAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.oauth2.jwt.Jwt;

/**
 * Authentication whose principal is the {@link CurrentUser}. Authorities are the user's permissions (for example
 * {@code PAYMENT_READ}) plus {@code ROLE_<role>}.
 */
public class CurrentUserAuthentication extends AbstractAuthenticationToken {

    private final CurrentUser user;
    private final Jwt jwt;

    public CurrentUserAuthentication(CurrentUser user, Jwt jwt) {
        super(authorities(user));
        this.user = user;
        this.jwt = jwt;
        setAuthenticated(true);
    }

    private static Collection<GrantedAuthority> authorities(CurrentUser user) {
        List<GrantedAuthority> authorities = new ArrayList<>();
        user.permissions().forEach(p -> authorities.add(new SimpleGrantedAuthority(p.name())));
        user.roles().forEach(r -> authorities.add(new SimpleGrantedAuthority("ROLE_" + r.name())));
        return authorities;
    }

    @Override
    public CurrentUser getPrincipal() {
        return user;
    }

    @Override
    public Jwt getCredentials() {
        return jwt;
    }

    @Override
    public String getName() {
        return user.id().toString();
    }
}
