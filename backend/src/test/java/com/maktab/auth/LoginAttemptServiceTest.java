package com.maktab.auth;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.maktab.auth.application.LoginAttemptService;
import com.maktab.common.MaktabException;
import com.maktab.support.MutableClock;
import java.time.Duration;
import org.junit.jupiter.api.Test;

class LoginAttemptServiceTest {

    private final MutableClock clock = new MutableClock();
    private final LoginAttemptService service = new LoginAttemptService(clock);

    @Test
    void locksAfterFiveFailuresAndIsCaseInsensitive() {
        for (int i = 0; i < 5; i++) {
            service.recordFailure("Teacher@Test.local");
        }
        assertThatThrownBy(() -> service.checkAllowed("teacher@test.local")).isInstanceOf(MaktabException.class);
    }

    @Test
    void fourFailuresDoNotLock() {
        for (int i = 0; i < 4; i++) {
            service.recordFailure("a@test.local");
        }
        assertThatCode(() -> service.checkAllowed("a@test.local")).doesNotThrowAnyException();
    }

    @Test
    void lockExpiresAfterFifteenMinutes() {
        for (int i = 0; i < 5; i++) {
            service.recordFailure("b@test.local");
        }
        clock.advance(Duration.ofMinutes(15).plusSeconds(1));
        assertThatCode(() -> service.checkAllowed("b@test.local")).doesNotThrowAnyException();
    }

    @Test
    void successResetsTheCounter() {
        for (int i = 0; i < 4; i++) {
            service.recordFailure("c@test.local");
        }
        service.recordSuccess("c@test.local");
        service.recordFailure("c@test.local");
        assertThatCode(() -> service.checkAllowed("c@test.local")).doesNotThrowAnyException();
    }

    @Test
    void failuresOutsideTheWindowStartANewCount() {
        for (int i = 0; i < 4; i++) {
            service.recordFailure("d@test.local");
        }
        clock.advance(Duration.ofMinutes(16));
        service.recordFailure("d@test.local");
        assertThatCode(() -> service.checkAllowed("d@test.local")).doesNotThrowAnyException();
    }
}
