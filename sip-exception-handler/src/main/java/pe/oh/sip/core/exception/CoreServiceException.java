package pe.oh.sip.core.exception;

/**
 * Thrown when an upstream core service returns an error.
 * Maps to HTTP 502 Bad Gateway.
 */
public class CoreServiceException extends RuntimeException {

    private final String serviceName;
    private final int upstreamStatus;

    public CoreServiceException(String serviceName, int upstreamStatus, String message) {
        super(message);
        this.serviceName = serviceName;
        this.upstreamStatus = upstreamStatus;
    }

    public CoreServiceException(String serviceName, String message) {
        this(serviceName, 0, message);
    }

    public String getServiceName() {
        return serviceName;
    }

    public int getUpstreamStatus() {
        return upstreamStatus;
    }
}
