package com.maktab.auth.application;

import com.maktab.auth.domain.RefreshToken;
import com.maktab.auth.persistence.RefreshTokenRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Clock;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RefreshTokenService {

    private static final SecureRandom RANDOM = new SecureRandom();

    private final RefreshTokenRepository repository;
    private final JwtProperties properties;
    private final Clock clock;

    public RefreshTokenService(RefreshTokenRepository repository, JwtProperties properties, Clock clock) {
        this.repository = repository;
        this.properties = properties;
        this.clock = clock;
    }

    /** Starts a new session (token family) for a fresh login. */
    @Transactional
    public IssuedRefreshToken issueNewFamily(UUID userId) {
        return issue(userId, UUID.randomUUID()).issued();
    }

    /**
     * Exchanges a valid refresh token for a new one in the same family. Presenting a token that was already
     * rotated means it was copied, so the whole family is revoked.
     */
    @Transactional(noRollbackFor = InvalidRefreshTokenException.class)
    public Rotation rotate(String rawToken) {
        Instant now = clock.instant();
        RefreshToken current = repository.findByTokenHash(hash(rawToken))
                .orElseThrow(InvalidRefreshTokenException::new);
        if (current.isRevoked()) {
            repository.revokeFamily(current.getFamilyId(), now);
            throw new InvalidRefreshTokenException();
        }
        if (current.isExpired(now)) {
            throw new InvalidRefreshTokenException();
        }
        Created next = issue(current.getUserId(), current.getFamilyId());
        current.rotateTo(next.entity().getId(), now);
        return new Rotation(current.getUserId(), next.issued());
    }

    @Transactional
    public Optional<UUID> revoke(String rawToken) {
        return repository.findByTokenHash(hash(rawToken)).map(token -> {
            token.revoke(clock.instant());
            return token.getUserId();
        });
    }

    @Transactional(propagation = Propagation.MANDATORY)
    public void revokeAllForUser(UUID userId) {
        repository.revokeAllForUser(userId, clock.instant());
    }

    private Created issue(UUID userId, UUID familyId) {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        String raw = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
        Instant now = clock.instant();
        Instant expiresAt = now.plus(properties.refreshTokenTtl());
        RefreshToken entity = repository.save(new RefreshToken(userId, familyId, hash(raw), now, expiresAt));
        return new Created(entity, new IssuedRefreshToken(raw, expiresAt));
    }

    static String hash(String rawToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(digest.digest(rawToken.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    public record IssuedRefreshToken(String value, Instant expiresAt) {
    }

    public record Rotation(UUID userId, IssuedRefreshToken token) {
    }

    private record Created(RefreshToken entity, IssuedRefreshToken issued) {
    }
}
