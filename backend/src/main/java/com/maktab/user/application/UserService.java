package com.maktab.user.application;

import com.maktab.audit.application.AuditService;
import com.maktab.audit.domain.AuditAction;
import com.maktab.auth.application.CurrentUser;
import com.maktab.auth.application.RefreshTokenService;
import com.maktab.common.BusinessValidationException;
import com.maktab.common.ConflictException;
import com.maktab.common.NotFoundException;
import com.maktab.user.api.CreateUserRequest;
import com.maktab.user.api.CreatedUserResponse;
import com.maktab.user.api.UpdateUserRequest;
import com.maktab.user.api.UserResponse;
import com.maktab.user.domain.Permission;
import com.maktab.user.domain.Role;
import com.maktab.user.domain.User;
import com.maktab.user.persistence.UserRepository;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * User administration. Every lookup is scoped to the caller's organisation, so an id from another organisation is
 * simply not found.
 */
@Service
public class UserService {

    private static final String ENTITY = "User";

    private final UserRepository users;
    private final PasswordEncoder passwordEncoder;
    private final TemporaryPasswordGenerator passwordGenerator;
    private final RefreshTokenService refreshTokens;
    private final AuditService audit;

    public UserService(UserRepository users, PasswordEncoder passwordEncoder,
            TemporaryPasswordGenerator passwordGenerator, RefreshTokenService refreshTokens, AuditService audit) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.passwordGenerator = passwordGenerator;
        this.refreshTokens = refreshTokens;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public Page<User> search(CurrentUser actor, String search, Role role, Boolean active, Pageable pageable) {
        String term = search == null || search.isBlank() ? null : search.trim();
        return users.search(actor.organisationId(), term, role, active, pageable);
    }

    @Transactional(readOnly = true)
    public UserResponse get(CurrentUser actor, UUID id) {
        return UserResponse.from(load(actor, id));
    }

    @Transactional
    public CreatedUserResponse create(CurrentUser actor, CreateUserRequest request) {
        String email = request.email().trim();
        if (users.existsByOrganisationIdAndEmail(actor.organisationId(), email)) {
            throw new ConflictException("A user with this email already exists");
        }
        String temporaryPassword = passwordGenerator.generate();
        User user = new User(actor.organisationId(), email, passwordEncoder.encode(temporaryPassword),
                request.firstName().trim(), request.lastName().trim(), request.roles());
        user.changePassword(user.getPasswordHash(), true);
        users.save(user);
        UserResponse response = UserResponse.from(user);
        audit.record(actor, AuditAction.USER_CREATED, ENTITY, user.getId(), null, response);
        return new CreatedUserResponse(response, temporaryPassword);
    }

    @Transactional
    public UserResponse update(CurrentUser actor, UUID id, UpdateUserRequest request) {
        User user = load(actor, id);
        UserResponse before = UserResponse.from(user);
        String email = request.email().trim();
        if (!email.equalsIgnoreCase(user.getEmail())
                && users.existsByOrganisationIdAndEmail(actor.organisationId(), email)) {
            throw new ConflictException("A user with this email already exists");
        }
        user.updateDetails(email, request.firstName().trim(), request.lastName().trim());
        UserResponse after = UserResponse.from(user);
        audit.record(actor, AuditAction.USER_UPDATED, ENTITY, id, before, after);
        return after;
    }

    @Transactional
    public UserResponse setActive(CurrentUser actor, UUID id, boolean active) {
        User user = load(actor, id);
        if (!active && user.getId().equals(actor.id())) {
            throw new BusinessValidationException("active", "You cannot deactivate your own account");
        }
        boolean before = user.isActive();
        user.setActive(active);
        if (!active) {
            refreshTokens.revokeAllForUser(user.getId());
        }
        audit.record(actor, active ? AuditAction.USER_ACTIVATED : AuditAction.USER_DEACTIVATED, ENTITY, id,
                Map.of("active", before), Map.of("active", active));
        return UserResponse.from(user);
    }

    @Transactional
    public UserResponse replaceRoles(CurrentUser actor, UUID id, Set<Role> roles) {
        User user = load(actor, id);
        if (user.getId().equals(actor.id()) && user.hasRole(Role.ADMIN) && !roles.contains(Role.ADMIN)) {
            throw new BusinessValidationException("roles", "You cannot remove your own ADMIN role");
        }
        Set<Role> before = user.getRoles();
        user.replaceRoles(roles);
        audit.record(actor, AuditAction.USER_ROLES_CHANGED, ENTITY, id, Map.of("roles", before),
                Map.of("roles", user.getRoles()));
        return UserResponse.from(user);
    }

    @Transactional
    public UserResponse replaceGrantedPermissions(CurrentUser actor, UUID id, Set<Permission> permissions) {
        User user = load(actor, id);
        Set<Permission> before = user.getGrantedPermissions();
        user.replaceGrantedPermissions(permissions);
        audit.record(actor, AuditAction.USER_PERMISSIONS_CHANGED, ENTITY, id, Map.of("grantedPermissions", before),
                Map.of("grantedPermissions", user.getGrantedPermissions()));
        return UserResponse.from(user);
    }

    @Transactional
    public CreatedUserResponse resetPassword(CurrentUser actor, UUID id) {
        User user = load(actor, id);
        String temporaryPassword = passwordGenerator.generate();
        user.changePassword(passwordEncoder.encode(temporaryPassword), true);
        refreshTokens.revokeAllForUser(user.getId());
        audit.record(actor, AuditAction.PASSWORD_RESET, ENTITY, id, null, Map.of("passwordReset", true));
        return new CreatedUserResponse(UserResponse.from(user), temporaryPassword);
    }

    private User load(CurrentUser actor, UUID id) {
        return users.findByIdAndOrganisationId(id, actor.organisationId())
                .orElseThrow(() -> new NotFoundException(ENTITY));
    }
}
