package com.maktab.auth.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.api.MeResponse;
import com.maktab.auth.api.TokenResponse;
import com.maktab.common.BusinessValidationException;
import com.maktab.common.NotFoundException;
import com.maktab.organisation.domain.Organisation;
import com.maktab.user.domain.User;
import com.maktab.user.persistence.UserRepository;
import java.time.Clock;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    /**
     * Compared against when the email is unknown, so a failed login takes the same time whether or not the account
     * exists.
     */
    private final String dummyHash;

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final AccessTokenService accessTokens;
    private final RefreshTokenService refreshTokens;
    private final LoginAttemptService loginAttempts;
    private final AuditService audit;
    private final Clock clock;

    public AuthService(UserRepository users, PasswordEncoder passwordEncoder, AccessTokenService accessTokens,
            RefreshTokenService refreshTokens, LoginAttemptService loginAttempts, AuditService audit, Clock clock) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.accessTokens = accessTokens;
        this.refreshTokens = refreshTokens;
        this.loginAttempts = loginAttempts;
        this.audit = audit;
        this.clock = clock;
        this.dummyHash = passwordEncoder.encode(UUID.randomUUID().toString());
    }

    @Transactional(noRollbackFor = InvalidCredentialsException.class)
    public TokenResponse login(String email, String password) {
        String normalisedEmail = email.trim();
        loginAttempts.checkAllowed(normalisedEmail);
        Optional<User> found = users.findByOrganisationIdAndEmail(Organisation.DEFAULT_ID, normalisedEmail);
        boolean passwordMatches = passwordEncoder.matches(password,
                found.map(User::getPasswordHash).orElse(dummyHash));

        if (found.isEmpty() || !passwordMatches || !found.get().isActive()) {
            loginAttempts.recordFailure(normalisedEmail);
            found.ifPresent(user -> audit.record(user.getOrganisationId(), user.getId(), AuditAction.LOGIN_FAILED,
                    "User", user.getId(), null, null));
            throw new InvalidCredentialsException();
        }

        User user = found.get();
        loginAttempts.recordSuccess(normalisedEmail);
        user.recordLogin(clock.instant());
        audit.record(user.getOrganisationId(), user.getId(), AuditAction.LOGIN_SUCCEEDED, "User", user.getId(),
                null, null);
        return tokens(user, refreshTokens.issueNewFamily(user.getId()));
    }

    @Transactional(noRollbackFor = InvalidRefreshTokenException.class)
    public TokenResponse refresh(String rawRefreshToken) {
        RefreshTokenService.Rotation rotation = refreshTokens.rotate(rawRefreshToken);
        User user = users.findById(rotation.userId())
                .filter(User::isActive)
                .orElseThrow(InvalidRefreshTokenException::new);
        return tokens(user, rotation.token());
    }

    @Transactional
    public void logout(String rawRefreshToken) {
        refreshTokens.revoke(rawRefreshToken);
    }

    @Transactional(readOnly = true)
    public MeResponse me(CurrentUser currentUser) {
        return MeResponse.from(load(currentUser));
    }

    @Transactional
    public void changePassword(CurrentUser currentUser, String currentPassword, String newPassword) {
        User user = load(currentUser);
        if (!passwordEncoder.matches(currentPassword, user.getPasswordHash())) {
            throw new BusinessValidationException("currentPassword", "Current password is incorrect");
        }
        if (passwordEncoder.matches(newPassword, user.getPasswordHash())) {
            throw new BusinessValidationException("newPassword",
                    "New password must be different from the current password");
        }
        user.changePassword(passwordEncoder.encode(newPassword), false);
        refreshTokens.revokeAllForUser(user.getId());
        audit.record(currentUser, AuditAction.PASSWORD_CHANGED, "User", user.getId(), null,
                Map.of("passwordChanged", true));
    }

    private User load(CurrentUser currentUser) {
        return users.findByIdAndOrganisationId(currentUser.id(), currentUser.organisationId())
                .orElseThrow(() -> new NotFoundException("User"));
    }

    private TokenResponse tokens(User user, RefreshTokenService.IssuedRefreshToken refresh) {
        AccessTokenService.IssuedToken access = accessTokens.issue(user);
        return new TokenResponse("Bearer", access.value(), access.expiresAt(), refresh.value(),
                refresh.expiresAt(), MeResponse.from(user));
    }
}
