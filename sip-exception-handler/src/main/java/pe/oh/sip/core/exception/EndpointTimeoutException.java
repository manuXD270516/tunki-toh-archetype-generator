package pe.oh.sip.core.exception;

/**
 * Thrown when an endpoint exceeds its configured timeout tier.
 * Maps to HTTP 504 Gateway Timeout.
 */
public class EndpointTimeoutException extends RuntimeException {

    public EndpointTimeoutException(String message) {
        super(message);
    }
}
