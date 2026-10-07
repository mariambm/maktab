# Database

PostgreSQL 17. The schema changes only through Flyway migrations in
`backend/src/main/resources/db/migration`; Hibernate runs with `ddl-auto=validate`.

## Conventions

- `uuid` primary keys (`gen_random_uuid()`), `timestamptz` for instants (UTC), `date` for calendar dates.
- `organisation_id` on top-level tables; one organisation (`00000000-0000-0000-0000-000000000001`) is seeded.
- Enumerations are `varchar` with `CHECK` constraints, mapped with `@Enumerated(STRING)`.
- Editable records have a `version` column for optimistic locking.
- Calculated values (attendance percentage, payment status, …) are not stored.

## Migrations

| Migration | Contents |
| --- | --- |
| `V1__extensions_and_organisation.sql` | `pgcrypto`, `citext`, `pg_trgm`; `organisation` |
| `V2__users_roles_permissions.sql` | `app_user` (email is `citext`, unique per organisation), `user_role`, `user_permission` |
| `V3__refresh_tokens.sql` | `refresh_token` (hash only, family id for reuse detection) |
| `V4__audit_log.sql` | `audit_log` (append-only, JSON old/new values) |

Planned (from the proposal): V5 students and parents, V6 levels and classes, V7 schedules, teachers and enrolments,
V8 curriculum, V9 lessons and attendance, V10 progress and targets, V11 behaviour and uniform, V12 payments.

## Phase 1 tables

```text
organisation   (id, name, time_zone, currency, attendance_threshold_pct, created_at, updated_at, version)
app_user       (id, organisation_id → organisation, email citext, password_hash, first_name, last_name,
                active, must_change_password, last_login_at, created_at, updated_at, version)
                UNIQUE (organisation_id, email)
user_role      (user_id → app_user, role ∈ ADMIN|ADMINISTRATOR|TEACHER)          PK (user_id, role)
user_permission(user_id → app_user, permission)                                   PK (user_id, permission)
refresh_token  (id, user_id → app_user, family_id, token_hash UNIQUE, expires_at, revoked_at,
                replaced_by → refresh_token, created_at)
audit_log      (id, organisation_id, user_id → app_user, action, entity_type, entity_id, occurred_at,
                old_value jsonb, new_value jsonb, ip_address)
```

## Seed data

Development accounts are created by `DevDataSeeder` when the `dev` profile is active and the user table is empty.
They use fake names and the password from `DEV_SEED_PASSWORD`. Students, classes, lessons and other seed data are
added with their phases.
