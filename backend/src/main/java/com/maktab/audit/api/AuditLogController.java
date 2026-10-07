package com.maktab.audit.api;

import com.maktab.audit.persistence.AuditLogRepository;
import com.maktab.auth.application.CurrentUser;
import com.maktab.common.PageResponse;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.time.Instant;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import tools.jackson.databind.ObjectMapper;

@RestController
@RequestMapping("/api/audit-log")
@PreAuthorize("hasAuthority('AUDIT_READ')")
public class AuditLogController {

    private final AuditLogRepository repository;
    private final ObjectMapper objectMapper;

    public AuditLogController(AuditLogRepository repository, ObjectMapper objectMapper) {
        this.repository = repository;
        this.objectMapper = objectMapper;
    }

    @GetMapping
    @Transactional(readOnly = true)
    public PageResponse<AuditEntryResponse> search(
            @AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) String entityType,
            @RequestParam(required = false) UUID entityId,
            @RequestParam(required = false) UUID userId,
            @RequestParam(required = false) Instant from,
            @RequestParam(required = false) Instant to,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "25") @Min(1) @Max(100) int size) {
        return PageResponse.of(
                repository.search(currentUser.organisationId(), entityType, entityId, userId, from, to,
                        PageRequest.of(page, size)),
                log -> AuditEntryResponse.from(log, objectMapper));
    }
}
