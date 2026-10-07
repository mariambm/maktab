package com.maktab.auth.application;

import com.maktab.common.ErrorCode;
import com.maktab.common.MaktabException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.stereotype.Service;

/**
 * Locks an email for 15 minutes after 5 failed logins within 15 minutes. In-memory, which is enough for a single
 * backend instance; move to the database if the backend is ever scaled out.
 */
@Service
public class LoginAttemptService {

    static final int MAX_FAILURES = 5;
    static final Duration WINDOW = Duration.ofMinutes(15);

    private final Clock clock;
    private final Map<String, Attempts> attempts = new ConcurrentHashMap<>();

    public LoginAttemptService(Clock clock) {
        this.clock = clock;
    }

    public void checkAllowed(String email) {
        Attempts current = attempts.get(key(email));
        if (current != null && current.lockedUntil() != null && clock.instant().isBefore(current.lockedUntil())) {
            throw new MaktabException(ErrorCode.TOO_MANY_REQUESTS,
                    "Too many failed attempts. Please try again in 15 minutes.");
        }
    }

    public void recordFailure(String email) {
        Instant now = clock.instant();
        attempts.compute(key(email), (k, current) -> {
            if (current == null || now.isAfter(current.windowStart().plus(WINDOW))) {
                return new Attempts(1, now, null);
            }
            int failures = current.failures() + 1;
            Instant lockedUntil = failures >= MAX_FAILURES ? now.plus(WINDOW) : null;
            return new Attempts(failures, current.windowStart(), lockedUntil);
        });
    }

    public void recordSuccess(String email) {
        attempts.remove(key(email));
    }

    private static String key(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private record Attempts(int failures, Instant windowStart, Instant lockedUntil) {
    }
}
