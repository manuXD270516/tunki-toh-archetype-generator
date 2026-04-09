/**
 * CACHE — Redis cache adapters and multi-level cache configuration.
 *
 * Multi-level cache (Caffeine L1 + Redis L2) applies ONLY to Producto layer (pd-*).
 * Negocio layer (bs-*) uses Redis for distributed locks only.
 */
package ${package}.${tipo}.${micro}.infrastructure.cache;
