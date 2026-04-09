package pe.oh.sip.core.timeout;

import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.Around;
import org.aspectj.lang.annotation.Aspect;
import org.aspectj.lang.reflect.MethodSignature;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import pe.oh.sip.core.exception.EndpointTimeoutException;

import java.lang.reflect.Method;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * AOP aspect that enforces per-endpoint timeouts using @EndpointTimeout annotation.
 * Runs at highest precedence to wrap the entire controller method execution.
 */
@Aspect
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class EndpointTimeoutAspect {

    private static final Logger log = LoggerFactory.getLogger(EndpointTimeoutAspect.class);

    @Around("@annotation(pe.oh.sip.core.timeout.EndpointTimeout)")
    public Object enforceTimeout(ProceedingJoinPoint pjp) throws Throwable {
        MethodSignature sig = (MethodSignature) pjp.getSignature();
        Method method = sig.getMethod();
        EndpointTimeout timeout = method.getAnnotation(EndpointTimeout.class);
        int timeoutMs = timeout.value() > 0 ? timeout.value() : timeout.tier().defaultMs;

        try {
            return CompletableFuture.supplyAsync(() -> {
                try {
                    return pjp.proceed();
                } catch (Throwable e) {
                    throw new CompletionException(e);
                }
            }).get(timeoutMs, TimeUnit.MILLISECONDS);
        } catch (TimeoutException e) {
            String methodName = pjp.getSignature().getName();
            log.warn("Endpoint timeout after {}ms on {}", timeoutMs, methodName);
            throw new EndpointTimeoutException(
                "Timeout after %dms on %s".formatted(timeoutMs, methodName)
            );
        } catch (java.util.concurrent.ExecutionException e) {
            throw e.getCause();
        }
    }
}
