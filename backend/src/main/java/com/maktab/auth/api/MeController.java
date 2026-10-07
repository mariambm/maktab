package com.maktab.auth.api;

import com.maktab.auth.application.AuthService;
import com.maktab.auth.application.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/me")
@PreAuthorize("isAuthenticated()")
public class MeController {

    private final AuthService authService;

    public MeController(AuthService authService) {
        this.authService = authService;
    }

    @GetMapping
    public MeResponse me(@AuthenticationPrincipal CurrentUser currentUser) {
        return authService.me(currentUser);
    }

    @PutMapping("/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void changePassword(@AuthenticationPrincipal CurrentUser currentUser,
            @Valid @RequestBody ChangePasswordRequest request) {
        authService.changePassword(currentUser, request.currentPassword(), request.newPassword());
    }
}
