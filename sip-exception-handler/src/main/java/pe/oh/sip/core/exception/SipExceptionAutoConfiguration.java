package pe.oh.sip.core.exception;

import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;

/**
 * Auto-configuration that registers the GlobalExceptionHandler
 * when this library is on the classpath.
 */
@Configuration
@ComponentScan(basePackageClasses = GlobalExceptionHandler.class)
public class SipExceptionAutoConfiguration {
}
