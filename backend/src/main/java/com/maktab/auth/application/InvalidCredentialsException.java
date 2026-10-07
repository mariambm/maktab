package com.maktab.auth.application;

import com.maktab.common.ErrorCode;
import com.maktab.common.MaktabException;

/** Deliberately generic: never reveals whether the email exists or the account is inactive. */
public class InvalidCredentialsException extends MaktabException {

    public InvalidCredentialsException() {
        super(ErrorCode.UNAUTHENTICATED, "Invalid email or password");
    }
}
