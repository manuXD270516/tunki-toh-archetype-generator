package ${package}.${tipo}.${micro}.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestClient;
import pe.oh.sip.core.client.CoreClientFactory;

/**
 * Core service RestClient beans.
 * Each bean gets header propagation + logging interceptors automatically.
 *
 * Add or remove beans based on which core services this MS needs.
 * See: implementation-guide.md § 9.3 — Core Service mapping
 */
@Configuration
public class CoreClientConfig {

    @Bean
    public RestClient coreCustomerClient(
            RestClient.Builder builder,
            @Value("${symbol_dollar}{core.services.customer.url}") String baseUrl) {
        return CoreClientFactory.create(builder, baseUrl);
    }

    @Bean
    public RestClient coreCacheClient(
            RestClient.Builder builder,
            @Value("${symbol_dollar}{core.services.cache.url}") String baseUrl) {
        return CoreClientFactory.create(builder, baseUrl);
    }
}
