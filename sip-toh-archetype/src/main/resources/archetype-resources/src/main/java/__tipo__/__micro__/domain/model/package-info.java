/**
 * DOMAIN MODELS — MongoDB documents and value objects.
 *
 * Example:
 * <pre>
 * @Document(collection = "products_cache")
 * public record ProductCache(
 *     @Id String id,
 *     String userId,
 *     BigDecimal availableBalance,
 *     Instant cachedAt,
 *     @Indexed(expireAfter = "60m") Instant ttl
 * ) {}
 * </pre>
 */
package ${package}.${tipo}.${micro}.domain.model;
