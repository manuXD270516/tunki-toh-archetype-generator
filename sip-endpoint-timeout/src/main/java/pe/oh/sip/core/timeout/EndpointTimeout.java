package pe.oh.sip.core.timeout;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Per-endpoint timeout annotation for Tunki TOH v3.4 controllers.
 *
 * Timeout tiers:
 *   TIER_1 (3s)  — Cache-backed reads    (GET /catalog, GET /banks)
 *   TIER_2 (5s)  — Direct reads          (GET /transactions, GET /campaigns)
 *   TIER_3 (10s) — Transactional writes  (POST /debit-card, POST /permissions)
 *   TIER_4 (15s) — Multi-step operations (GET /statements/{id}/pdf)
 *
 * Usage:
 * <pre>
 * @GetMapping("/catalog")
 * @EndpointTimeout(tier = Tier.TIER_1)
 * public ResponseEntity<CatalogResponse> getCatalog() { ... }
 * </pre>
 */
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface EndpointTimeout {

    /** Custom timeout in milliseconds. Overrides tier default if > 0. */
    int value() default 0;

    /** Timeout tier with predefined defaults. */
    Tier tier() default Tier.TIER_2;

    enum Tier {
        TIER_1(3000),    // Cache-backed reads
        TIER_2(5000),    // Direct reads
        TIER_3(10000),   // Transactional writes
        TIER_4(15000);   // Multi-step operations

        public final int defaultMs;

        Tier(int ms) {
            this.defaultMs = ms;
        }
    }
}
