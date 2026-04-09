/**
 * OUTPUT PORTS — Interfaces for external integrations (core services, repositories).
 *
 * Example:
 * <pre>
 * public interface CoreCustomerPort {
 *     CustomerData getCustomer(String userId);
 * }
 * </pre>
 *
 * Dependency rule: infrastructure/ implements these ports.
 *                  domain/ NEVER imports from infrastructure/.
 */
package ${package}.${tipo}.${micro}.domain.port.out;
