package com.maktab.audit.application;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.json.JsonMapper;

class AuditSanitizerTest {

    private final JsonMapper mapper = JsonMapper.builder().build();

    @Test
    void removesSecretsAtAnyDepth() {
        JsonNode node = mapper.readTree("""
                {"email":"a@b.c","password":"x","nested":{"passwordHash":"$2a","items":[{"refreshToken":"t","ok":1}]},
                 "temporaryPassword":"p"}
                """);

        String result = AuditSanitizer.sanitize(node).toString();

        assertThat(result).contains("a@b.c", "\"ok\":1")
                .doesNotContain("password", "passwordHash", "refreshToken", "temporaryPassword", "$2a");
    }
}
