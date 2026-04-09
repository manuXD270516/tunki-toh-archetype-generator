package pe.oh.sip.core.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;

import java.io.IOException;

/**
 * Logs outgoing HTTP requests to core services with timing information.
 */
public class LoggingInterceptor implements ClientHttpRequestInterceptor {

    private static final Logger log = LoggerFactory.getLogger(LoggingInterceptor.class);

    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body,
            ClientHttpRequestExecution execution) throws IOException {

        long start = System.currentTimeMillis();
        log.debug("Core request: {} {}", request.getMethod(), request.getURI());

        ClientHttpResponse response = execution.execute(request, body);

        long elapsed = System.currentTimeMillis() - start;
        log.info("Core response: {} {} -> {} ({}ms)",
            request.getMethod(), request.getURI(), response.getStatusCode(), elapsed);

        return response;
    }
}
