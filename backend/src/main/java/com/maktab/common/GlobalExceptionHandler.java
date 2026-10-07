package com.maktab.common;

import jakarta.servlet.http.HttpServletRequest;
import java.util.LinkedHashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.HandlerMethodValidationException;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.web.servlet.resource.NoResourceFoundException;

/**
 * Turns every exception into the {@link ApiError} shape. Unexpected errors are logged with the correlation id and
 * answered with a generic message; stack traces never reach the client.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ResponseEntity<ApiError> handleInvalidBody(MethodArgumentNotValidException ex, HttpServletRequest request) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fieldErrors.putIfAbsent(error.getField(), error.getDefaultMessage());
        }
        ex.getBindingResult().getGlobalErrors()
                .forEach(error -> fieldErrors.putIfAbsent(error.getObjectName(), error.getDefaultMessage()));
        return respond(ErrorCode.VALIDATION_ERROR, "Validation failed", request, fieldErrors);
    }

    @ExceptionHandler(HandlerMethodValidationException.class)
    ResponseEntity<ApiError> handleInvalidParameters(HandlerMethodValidationException ex, HttpServletRequest request) {
        Map<String, String> fieldErrors = new LinkedHashMap<>();
        ex.getParameterValidationResults().forEach(result -> {
            String name = result.getMethodParameter().getParameterName();
            result.getResolvableErrors()
                    .forEach(error -> fieldErrors.putIfAbsent(name, error.getDefaultMessage()));
        });
        return respond(ErrorCode.VALIDATION_ERROR, "Validation failed", request, fieldErrors);
    }

    @ExceptionHandler(BusinessValidationException.class)
    ResponseEntity<ApiError> handleBusinessValidation(BusinessValidationException ex, HttpServletRequest request) {
        return respond(ErrorCode.VALIDATION_ERROR, ex.getMessage(), request, ex.fieldErrors());
    }

    @ExceptionHandler(MaktabException.class)
    ResponseEntity<ApiError> handleMaktab(MaktabException ex, HttpServletRequest request) {
        return respond(ex.code(), ex.getMessage(), request, null);
    }

    @ExceptionHandler({HttpMessageNotReadableException.class, MissingServletRequestParameterException.class})
    ResponseEntity<ApiError> handleUnreadable(Exception ex, HttpServletRequest request) {
        return respond(ErrorCode.MALFORMED_REQUEST, "The request could not be read", request, null);
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    ResponseEntity<ApiError> handleTypeMismatch(MethodArgumentTypeMismatchException ex, HttpServletRequest request) {
        return respond(ErrorCode.VALIDATION_ERROR, "Validation failed", request,
                Map.of(ex.getName(), "Invalid value"));
    }

    @ExceptionHandler(NoResourceFoundException.class)
    ResponseEntity<ApiError> handleNoResource(NoResourceFoundException ex, HttpServletRequest request) {
        return respond(ErrorCode.NOT_FOUND, "Not found", request, null);
    }

    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    ResponseEntity<ApiError> handleMethod(HttpRequestMethodNotSupportedException ex, HttpServletRequest request) {
        return respond(ErrorCode.METHOD_NOT_ALLOWED, "Method not allowed", request, null);
    }

    @ExceptionHandler({DataIntegrityViolationException.class, ObjectOptimisticLockingFailureException.class})
    ResponseEntity<ApiError> handleConflict(Exception ex, HttpServletRequest request) {
        log.info("Conflict on {}: {}", request.getRequestURI(), ex.getClass().getSimpleName());
        return respond(ErrorCode.CONFLICT, "The change conflicts with existing data. Reload and try again.",
                request, null);
    }

    @ExceptionHandler(AccessDeniedException.class)
    ResponseEntity<ApiError> handleAccessDenied(AccessDeniedException ex, HttpServletRequest request) {
        return respond(ErrorCode.FORBIDDEN, "You do not have permission to do this", request, null);
    }

    @ExceptionHandler(AuthenticationException.class)
    ResponseEntity<ApiError> handleAuthentication(AuthenticationException ex, HttpServletRequest request) {
        return respond(ErrorCode.UNAUTHENTICATED, "Authentication required", request, null);
    }

    @ExceptionHandler(Exception.class)
    ResponseEntity<ApiError> handleUnexpected(Exception ex, HttpServletRequest request) {
        log.error("Unexpected error on {} {}", request.getMethod(), request.getRequestURI(), ex);
        return respond(ErrorCode.INTERNAL_ERROR, "Something went wrong. Please try again.", request, null);
    }

    private static ResponseEntity<ApiError> respond(ErrorCode code, String message, HttpServletRequest request,
            Map<String, String> fieldErrors) {
        return ResponseEntity.status(code.status())
                .body(ApiError.of(code, message, request.getRequestURI(), fieldErrors));
    }
}
