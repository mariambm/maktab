package com.maktab.user.api;

import com.maktab.auth.application.CurrentUser;
import com.maktab.common.PageResponse;
import com.maktab.user.application.UserService;
import com.maktab.user.domain.Role;
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
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
@PreAuthorize("hasAuthority('USER_MANAGE')")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public PageResponse<UserResponse> list(
            @AuthenticationPrincipal CurrentUser currentUser,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Role role,
            @RequestParam(required = false) Boolean active,
            @RequestParam(defaultValue = "0") @Min(0) int page,
            @RequestParam(defaultValue = "25") @Min(1) @Max(100) int size) {
        PageRequest pageable = PageRequest.of(page, size, Sort.by("lastName", "firstName"));
        return PageResponse.of(userService.search(currentUser, search, role, active, pageable), UserResponse::from);
    }

    @GetMapping("/{id}")
    public UserResponse get(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id) {
        return userService.get(currentUser, id);
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public CreatedUserResponse create(@AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody CreateUserRequest request) {
        return userService.create(currentUser, request);
    }

    @PutMapping("/{id}")
    public UserResponse update(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody UpdateUserRequest request) {
        return userService.update(currentUser, id, request);
    }

    @PatchMapping("/{id}/status")
    public UserResponse updateStatus(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody UpdateStatusRequest request) {
        return userService.setActive(currentUser, id, request.active());
    }

    @PutMapping("/{id}/roles")
    public UserResponse updateRoles(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody UpdateRolesRequest request) {
        return userService.replaceRoles(currentUser, id, request.roles());
    }

    @PutMapping("/{id}/permissions")
    public UserResponse updatePermissions(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID id,
            @Valid @RequestBody UpdatePermissionsRequest request) {
        return userService.replaceGrantedPermissions(currentUser, id, request.permissions());
    }

    @PostMapping("/{id}/password-reset")
    public CreatedUserResponse resetPassword(@AuthenticationPrincipal CurrentUser currentUser,
            @PathVariable UUID id) {
        return userService.resetPassword(currentUser, id);
    }
}
