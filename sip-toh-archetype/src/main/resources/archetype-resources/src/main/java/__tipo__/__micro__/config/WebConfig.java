package ${package}.${tipo}.${micro}.config;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.MDC;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.io.IOException;

@Configuration
public class WebConfig {

    /**
     * Extracts X-Trace-Id and X-User-Id from incoming requests
     * and sets them in MDC for structured logging.
     */
    @Component
    @Order(0)
    static class TraceIdFilter implements Filter {

        @Override
        public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
                throws IOException, ServletException {
            HttpServletRequest request = (HttpServletRequest) req;

            String traceId = request.getHeader("X-Trace-Id");
            if (traceId == null) {
                traceId = request.getHeader("X-Request-Id");
            }
            if (traceId != null) {
                MDC.put("traceId", traceId);
            }

            String userId = request.getHeader("X-User-Id");
            if (userId != null) {
                MDC.put("userId", userId);
            }

            try {
                chain.doFilter(req, res);
            } finally {
                MDC.clear();
            }
        }
    }
}
