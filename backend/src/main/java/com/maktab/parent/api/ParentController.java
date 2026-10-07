package com.maktab.parent.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.common.PageResponse;
import com.maktab.parent.application.ParentService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.UUID;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/parents")
public class ParentController {

    private final ParentService parentService;

    public ParentController(ParentService parentService) {
        this.parentService = parentService;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('PARENT_READ')")
    public PageResponse<ParentResponse> list(
            @AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "25") @Min(1) @Max(100) int size) {
        PageRequest pageable = PageRequest.of(page, size, Sort.by("lastName", "firstName", "id"));
        return parentService.search(currentUser, search, pageable);
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('PARENT_READ')")
    public ParentResponse get(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id) {
        return parentService.get(currentUser, id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAuthority('PARENT_WRITE')")
    public ParentResponse create(@AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody ParentRequest request) {
        return parentService.create(currentUser, request);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('PARENT_WRITE')")
    public ParentResponse update(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody ParentRequest request) {
        return parentService.update(currentUser, id, request);
    }
}
