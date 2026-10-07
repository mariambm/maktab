package com.maktab.common;

import java.util.Map;

/**
 * A validation failure that Bean Validation cannot express, such as "you cannot remove your own ADMIN role".
 */
public class BusinessValidationException extends MaktabException {

    private final Map<String, String> fieldErrors;

    public BusinessValidationException(String field, String message) {
        super(ErrorCode.VALIDATION_ERROR, message);
        this.fieldErrors = Map.of(field, message);
    }

    public Map<String, String> fieldErrors() {
        return fieldErrors;
    }
}
