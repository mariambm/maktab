package com.maktab.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Swagger UI is only exposed when {@code springdoc.api-docs.enabled=true} (the dev profile). */
@Configuration
public class OpenApiConfig {

    @Bean
    OpenAPI maktabOpenApi() {
        return new OpenAPI()
                .info(new Info().title("Maktab API").version("v1")
                        .description("Maktab — Mosque Education Management System"))
                .components(new Components().addSecuritySchemes("bearer",
                        new SecurityScheme().type(SecurityScheme.Type.HTTP).scheme("bearer").bearerFormat("JWT")))
                .addSecurityItem(new SecurityRequirement().addList("bearer"));
    }
}
