package com.maktab.common;

public class ConflictException extends MaktabException {

    public ConflictException(String message) {
        super(ErrorCode.CONFLICT, message);
    }
}
