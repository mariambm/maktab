package com.maktab.audit.application;

import com.maktab.audit.domain.AuditAction;
import com.maktab.audit.domain.AuditLog;
import com.maktab.audit.persistence.AuditLogRepository;
import com.maktab.auth.application.CurrentUser;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Clock;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/**
 * Writes audit entries in the caller's transaction, so an entry exists exactly when the change it describes does.
 */
@Service
public class AuditService {

    private final AuditLogRepository repository;
    private final ObjectMapper objectMapper;
    private final Clock clock;

    public AuditService(AuditLogRepository repository, ObjectMapper objectMapper, Clock clock) {
        this.repository = repository;
        this.objectMapper = objectMapper;
        this.clock = clock;
    }

    @Transactional(propagation = Propagation.REQUIRED)
    public void record(CurrentUser actor, AuditAction action, String entityType, UUID entityId, Object oldValue,
            Object newValue) {
        record(actor.organisationId(), actor.id(), action, entityType, entityId, oldValue, newValue);
    }

    @Transactional(propagation = Propagation.REQUIRED)
    public void record(UUID organisationId, UUID userId, AuditAction action, String entityType, UUID entityId,
            Object oldValue, Object newValue) {
        repository.save(new AuditLog(organisationId, userId, action.name(), entityType, entityId, clock.instant(),
                toJson(oldValue), toJson(newValue), clientIp()));
    }

    private String toJson(Object value) {
        if (value == null) {
            return null;
        }
        JsonNode tree = AuditSanitizer.sanitize(objectMapper.valueToTree(value));
        return objectMapper.writeValueAsString(tree);
    }

    private static String clientIp() {
        if (RequestContextHolder.getRequestAttributes() instanceof ServletRequestAttributes attributes) {
            HttpServletRequest request = attributes.getRequest();
            return request.getRemoteAddr();
        }
        return null;
    }
}
