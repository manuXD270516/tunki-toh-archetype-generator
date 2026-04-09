package pe.oh.sip.core.exception;

import java.time.Instant;
import org.slf4j.MDC;

/**
 * Standard error response for all Tunki TOH v3.4 microservices.
 * Propagates traceId from X-Trace-Id header via MDC.
 */
public record ErrorResponse(
    String code,
    String message,
    Instant timestamp,
    String traceId
) {
    public ErrorResponse(String code, String message, Instant timestamp) {
        this(code, message, timestamp, MDC.get("traceId"));
    }

    public static ErrorResponse of(String code, String message) {
        return new ErrorResponse(code, message, Instant.now());
    }
}
