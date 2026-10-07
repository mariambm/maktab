package com.maktab.common;

/**
 * Thrown when a record does not exist or is outside the caller's scope. Both cases look identical to the caller,
 * so the API never reveals whether another organisation's or teacher's record exists.
 */
public class NotFoundException extends MaktabException {

    public NotFoundException(String entity) {
        super(ErrorCode.NOT_FOUND, entity + " not found");
    }
}
