package com.maktab.auth.application;

import com.maktab.common.ErrorCode;
import com.maktab.common.MaktabException;

public class InvalidRefreshTokenException extends MaktabException {

    public InvalidRefreshTokenException() {
        super(ErrorCode.UNAUTHENTICATED, "Your session has expired. Please log in again.");
    }
}
