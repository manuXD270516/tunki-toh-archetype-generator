/**
 * CORE SERVICE ADAPTERS — Implement output ports for external service calls.
 *
 * Example:
 * <pre>
 * @Component
 * public class CoreCustomerAdapter implements CoreCustomerPort {
 *     private final RestClient coreCustomerClient;
 *
 *     @Override
 *     @CircuitBreaker(name = "coreCustomer", fallbackMethod = "fallback")
 *     @Retry(name = "coreCustomer")
 *     public CustomerData getCustomer(String userId) {
 *         return coreCustomerClient.get()
 *             .uri("/us-core-customer/v1/customers/{id}", userId)
 *             .retrieve()
 *             .body(CustomerData.class);
 *     }
 * }
 * </pre>
 */
package ${package}.${tipo}.${micro}.infrastructure.adapter;
