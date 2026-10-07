package com.maktab.common;

import com.fasterxml.jackson.annotation.JsonInclude;
import java.time.Instant;
import java.util.Map;

/**
 * The single error shape returned by every endpoint. Never carries stack traces or internal details.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record ApiError(
        Instant timestamp,
        int status,
        String error,
        String message,
        String path,
        String correlationId,
        Map<String, String> fieldErrors) {

    public static ApiError of(ErrorCode code, String message, String path, Map<String, String> fieldErrors) {
        return new ApiError(Instant.now(), code.status().value(), code.name(), message, path,
                CorrelationIdFilter.currentId(), fieldErrors);
    }
}
