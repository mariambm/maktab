package com.maktab.audit.api;

import com.maktab.audit.domain.AuditLog;
import java.time.Instant;
import java.util.UUID;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

public record AuditEntryResponse(
        UUID id,
        UUID userId,
        String action,
        String entityType,
        UUID entityId,
        Instant occurredAt,
        JsonNode oldValue,
        JsonNode newValue) {

    static AuditEntryResponse from(AuditLog log, ObjectMapper mapper) {
        return new AuditEntryResponse(log.getId(), log.getUserId(), log.getAction(), log.getEntityType(),
                log.getEntityId(), log.getOccurredAt(), parse(log.getOldValue(), mapper),
                parse(log.getNewValue(), mapper));
    }

    private static JsonNode parse(String json, ObjectMapper mapper) {
        return json == null ? null : mapper.readTree(json);
    }
}
