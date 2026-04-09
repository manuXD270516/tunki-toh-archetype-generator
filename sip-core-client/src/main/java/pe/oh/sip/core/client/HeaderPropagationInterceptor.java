package pe.oh.sip.core.client;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.io.IOException;
import java.util.List;

/**
 * Propagates ecosystem headers through the entire call chain.
 * Supports multi-canal headers (v3.4): SIP, AGORA, and future channels.
 *
 * Header flow: App -> Apigee -> Dispatcher -> MS -> Core Service
 */
public class HeaderPropagationInterceptor implements ClientHttpRequestInterceptor {

    private static final List<String> PROPAGATED_HEADERS = List.of(
        // Identity & tracing
        "X-User-Id", "X-Request-Id", "X-Trace-Id", "X-Transactional-Id", "Authorization",
        // Multi-canal headers (v3.4)
        "X-Platform", "X-App-Config", "X-App-Version",
        "X-Device-Id", "X-Device-UUID", "X-Device-Ip", "X-Model", "X-Channel",
        // FOH integration
        "X-Auth-FOH"
    );

    @Override
    public ClientHttpResponse intercept(HttpRequest request, byte[] body,
            ClientHttpRequestExecution execution) throws IOException {

        ServletRequestAttributes attrs =
            (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();

        if (attrs != null) {
            HttpServletRequest servletRequest = attrs.getRequest();
            for (String header : PROPAGATED_HEADERS) {
                String value = servletRequest.getHeader(header);
                if (value != null) {
                    request.getHeaders().set(header, value);
                }
            }
        }

        return execution.execute(request, body);
    }
}
