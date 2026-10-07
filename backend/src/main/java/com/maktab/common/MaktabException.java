package com.maktab.common;

/**
 * Base class for expected business errors; the message is safe to show to the user.
 */
public class MaktabException extends RuntimeException {

    private final ErrorCode code;

    public MaktabException(ErrorCode code, String message) {
        super(message);
        this.code = code;
    }

    public ErrorCode code() {
        return code;
    }
}
