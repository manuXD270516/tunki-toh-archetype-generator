package pe.oh.sip.core.exception;

/**
 * Thrown when an idempotency key has already been used with a different payload.
 * Maps to HTTP 409 Conflict.
 */
public class IdempotencyConflictException extends RuntimeException {

    public IdempotencyConflictException(String message) {
        super(message);
    }
}
