package ${package}.${tipo}.${micro}.api;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import pe.oh.sip.core.timeout.EndpointTimeout;

import java.time.Instant;
import java.util.Map;

/**
 * Sample controller — replace with your actual controllers.
 * Demonstrates @EndpointTimeout usage and standard response format.
 */
@RestController
@RequestMapping("/v1")
public class HealthCheckController {

    @GetMapping("/ping")
    @EndpointTimeout(tier = EndpointTimeout.Tier.TIER_1)
    public ResponseEntity<Map<String, Object>> ping() {
        return ResponseEntity.ok(Map.of(
            "service", "${msName}",
            "status", "UP",
            "timestamp", Instant.now().toString()
        ));
    }
}
