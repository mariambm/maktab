package com.maktab.user.domain;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;
import jakarta.persistence.Version;
import java.time.Instant;
import java.util.Collection;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "app_user")
public class User {

    @Id
    private UUID id;

    @Column(name = "organisation_id", nullable = false, updatable = false)
    private UUID organisationId;

    @Column(nullable = false, columnDefinition = "citext")
    private String email;

    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Column(name = "first_name", nullable = false)
    private String firstName;

    @Column(name = "last_name", nullable = false)
    private String lastName;

    @Column(nullable = false)
    private boolean active = true;

    @Column(name = "must_change_password", nullable = false)
    private boolean mustChangePassword;

    @Column(name = "last_login_at")
    private Instant lastLoginAt;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "user_role", joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "role", nullable = false)
    @Enumerated(EnumType.STRING)
    private Set<Role> roles = new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "user_permission", joinColumns = @JoinColumn(name = "user_id"))
    @Column(name = "permission", nullable = false)
    @Enumerated(EnumType.STRING)
    private Set<Permission> grantedPermissions = new HashSet<>();

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    @Version
    private long version;

    protected User() {
    }

    public User(UUID organisationId, String email, String passwordHash, String firstName, String lastName,
            Collection<Role> roles) {
        this.id = UUID.randomUUID();
        this.organisationId = organisationId;
        this.email = email;
        this.passwordHash = passwordHash;
        this.firstName = firstName;
        this.lastName = lastName;
        this.roles = new HashSet<>(roles);
    }

    @PrePersist
    void onCreate() {
        createdAt = Instant.now();
        updatedAt = createdAt;
    }

    @PreUpdate
    void onUpdate() {
        updatedAt = Instant.now();
    }

    public Set<Permission> effectivePermissions() {
        return RolePermissions.effective(roles, grantedPermissions);
    }

    public boolean hasRole(Role role) {
        return roles.contains(role);
    }

    public void updateDetails(String email, String firstName, String lastName) {
        this.email = email;
        this.firstName = firstName;
        this.lastName = lastName;
    }

    public void changePassword(String passwordHash, boolean mustChangePassword) {
        this.passwordHash = passwordHash;
        this.mustChangePassword = mustChangePassword;
    }

    public void replaceRoles(Collection<Role> newRoles) {
        roles.clear();
        roles.addAll(newRoles);
    }

    public void replaceGrantedPermissions(Collection<Permission> permissions) {
        grantedPermissions.clear();
        grantedPermissions.addAll(permissions);
    }

    public void setActive(boolean active) {
        this.active = active;
    }

    public void recordLogin(Instant at) {
        this.lastLoginAt = at;
    }

    public UUID getId() {
        return id;
    }

    public UUID getOrganisationId() {
        return organisationId;
    }

    public String getEmail() {
        return email;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public boolean isActive() {
        return active;
    }

    public boolean isMustChangePassword() {
        return mustChangePassword;
    }

    public Instant getLastLoginAt() {
        return lastLoginAt;
    }

    public Set<Role> getRoles() {
        return roles.isEmpty() ? EnumSet.noneOf(Role.class) : EnumSet.copyOf(roles);
    }

    public Set<Permission> getGrantedPermissions() {
        return grantedPermissions.isEmpty() ? EnumSet.noneOf(Permission.class) : EnumSet.copyOf(grantedPermissions);
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
