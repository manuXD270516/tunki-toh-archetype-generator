package pe.oh.sip.core.exception;

/**
 * Thrown when a distributed lock cannot be acquired (operation already in progress).
 * Maps to HTTP 429 Too Many Requests.
 */
public class LockNotAcquiredException extends RuntimeException {

    public LockNotAcquiredException(String message) {
        super(message);
    }
}
