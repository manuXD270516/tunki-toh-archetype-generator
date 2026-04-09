package pe.oh.sip.core.exception;

import io.github.resilience4j.circuitbreaker.CallNotPermittedException;
import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Global exception handler for all Tunki TOH v3.4 microservices.
 * Maps domain exceptions to standardized HTTP responses with ErrorResponse format.
 *
 * HTTP status mapping:
 *   400 — Validation error (ConstraintViolation, MethodArgumentNotValid)
 *   404 — Resource not found
 *   409 — Idempotency conflict
 *   429 — Lock not acquired (operation in progress)
 *   502 — Core service error (upstream failure)
 *   503 — Circuit breaker open (service unavailable)
 *   504 — Endpoint timeout exceeded
 *   500 — Unhandled exception (fallback)
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(EndpointTimeoutException.class)
    public ResponseEntity<ErrorResponse> handleTimeout(EndpointTimeoutException e) {
        log.warn("Endpoint timeout: {}", e.getMessage());
        return ResponseEntity.status(504).body(ErrorResponse.of("TIMEOUT", e.getMessage()));
    }

    @ExceptionHandler(LockNotAcquiredException.class)
    public ResponseEntity<ErrorResponse> handleLock(LockNotAcquiredException e) {
        log.warn("Lock not acquired: {}", e.getMessage());
        return ResponseEntity.status(429).body(
            ErrorResponse.of("OPERATION_IN_PROGRESS", "Another operation is in progress. Try again later.")
        );
    }

    @ExceptionHandler(IdempotencyConflictException.class)
    public ResponseEntity<ErrorResponse> handleIdempotency(IdempotencyConflictException e) {
        log.warn("Idempotency conflict: {}", e.getMessage());
        return ResponseEntity.status(409).body(ErrorResponse.of("IDEMPOTENCY_CONFLICT", e.getMessage()));
    }

    @ExceptionHandler(CoreServiceException.class)
    public ResponseEntity<ErrorResponse> handleCoreError(CoreServiceException e) {
        log.error("Core service error [{}]: {}", e.getServiceName(), e.getMessage());
        return ResponseEntity.status(502).body(
            ErrorResponse.of("CORE_SERVICE_ERROR", "Upstream service error: " + e.getServiceName())
        );
    }

    @ExceptionHandler(CallNotPermittedException.class)
    public ResponseEntity<ErrorResponse> handleCircuitOpen(CallNotPermittedException e) {
        log.warn("Circuit breaker open: {}", e.getMessage());
        return ResponseEntity.status(503).body(
            ErrorResponse.of("SERVICE_UNAVAILABLE", "Service temporarily unavailable. Please retry.")
        );
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleNotFound(ResourceNotFoundException e) {
        return ResponseEntity.status(404).body(ErrorResponse.of("NOT_FOUND", e.getMessage()));
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<ErrorResponse> handleValidation(ConstraintViolationException e) {
        return ResponseEntity.status(400).body(ErrorResponse.of("VALIDATION_ERROR", e.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleMethodArgument(MethodArgumentNotValidException e) {
        String message = e.getBindingResult().getFieldErrors().stream()
            .map(f -> f.getField() + ": " + f.getDefaultMessage())
            .reduce((a, b) -> a + "; " + b)
            .orElse("Validation failed");
        return ResponseEntity.status(400).body(ErrorResponse.of("VALIDATION_ERROR", message));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponse> handleUnexpected(Exception e) {
        log.error("Unhandled exception: {}", e.getMessage(), e);
        return ResponseEntity.status(500).body(
            ErrorResponse.of("INTERNAL_ERROR", "An unexpected error occurred")
        );
    }
}
