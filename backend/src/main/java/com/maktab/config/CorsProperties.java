package com.maktab.config;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Browser origins allowed to call the API (for a future web portal or Flutter web in development). The mobile app
 * is not subject to CORS. Empty means no cross-origin browser access.
 */
@ConfigurationProperties(prefix = "maktab.cors")
public record CorsProperties(List<String> allowedOrigins) {

    public CorsProperties {
        allowedOrigins = allowedOrigins == null
                ? List.of()
                : allowedOrigins.stream().map(String::trim).filter(s -> !s.isEmpty()).toList();
    }
}
