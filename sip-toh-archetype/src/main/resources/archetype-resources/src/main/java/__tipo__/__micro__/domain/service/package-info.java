/**
 * DOMAIN SERVICES — Business logic orchestrators.
 *
 * Services depend ONLY on ports (interfaces), never on infrastructure directly.
 *
 * Example:
 * <pre>
 * @Service
 * public class CatalogService implements CatalogUseCase {
 *     private final CoreCustomerPort customerPort;
 *     private final ProductCacheRepository cacheRepo;
 *     // ...
 * }
 * </pre>
 */
package ${package}.${tipo}.${micro}.domain.service;
