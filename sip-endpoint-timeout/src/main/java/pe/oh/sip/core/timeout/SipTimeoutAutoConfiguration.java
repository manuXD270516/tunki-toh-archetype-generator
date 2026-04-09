package pe.oh.sip.core.timeout;

import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.EnableAspectJAutoProxy;

@Configuration
@EnableAspectJAutoProxy
@ComponentScan(basePackageClasses = EndpointTimeoutAspect.class)
public class SipTimeoutAutoConfiguration {
}
