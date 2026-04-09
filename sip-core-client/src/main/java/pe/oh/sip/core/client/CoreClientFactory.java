package pe.oh.sip.core.client;

import org.springframework.web.client.RestClient;

/**
 * Factory for creating pre-configured RestClient instances for core service integration.
 * Each client includes header propagation and logging interceptors.
 *
 * Usage in @Configuration:
 * <pre>
 * @Bean
 * public RestClient coreCustomerClient(RestClient.Builder builder) {
 *     return CoreClientFactory.create(builder, "${core.services.customer.url}");
 * }
 * </pre>
 */
public final class CoreClientFactory {

    private CoreClientFactory() {
    }

    /**
     * Creates a RestClient with standard interceptors for core service communication.
     *
     * @param builder  Spring-provided RestClient.Builder
     * @param baseUrl  Core service base URL (from application.yml)
     * @return configured RestClient
     */
    public static RestClient create(RestClient.Builder builder, String baseUrl) {
        return builder
            .baseUrl(baseUrl)
            .defaultHeader("Content-Type", "application/json")
            .requestInterceptor(new HeaderPropagationInterceptor())
            .requestInterceptor(new LoggingInterceptor())
            .build();
    }
}
