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
| `V5__students_and_parents.sql` | `student`, `parent_guardian`, `student_parent` |
| `V6__curriculum_levels_and_classes.sql` | `curriculum_level`, `class_group` |
| `V7__class_schedule_teachers_enrolments.sql` | `class_schedule`, `class_teacher`, `class_enrollment` |

Planned (from the proposal): V8 curriculum, V9 lessons and attendance, V10 progress and targets, V11 behaviour and
uniform, V12 payments.

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

## Phase 2 tables

```text
student          (id, organisation_id, first_name, last_name, date_of_birth, gender NULL ∈ FEMALE|MALE,
                  status ∈ ACTIVE|INACTIVE, joined_on, left_on NULL, notes NULL, search_name (generated), …)
                  CHECK left_on >= joined_on;  CHECK (status = INACTIVE) = (left_on IS NOT NULL)
parent_guardian  (id, organisation_id, first_name, last_name, phone, email NULL citext,
                  user_id NULL → app_user (reserved for a parent portal), search_name (generated), …)
student_parent   (student_id → student, parent_guardian_id → parent_guardian,
                  relationship ∈ MOTHER|FATHER|GUARDIAN|OTHER, is_primary_contact)
                  PK (student_id, parent_guardian_id);  at most one primary contact per student
curriculum_level (id, organisation_id, name, sort_order)                      UNIQUE (organisation_id, name)
class_group      (id, organisation_id, curriculum_level_id → curriculum_level, name, room NULL, active)
                  UNIQUE (organisation_id, name)
class_schedule   (id, class_group_id → class_group, weekday 1..7 (ISO, Monday = 1), start_time, end_time)
                  CHECK end_time > start_time;  UNIQUE (class_group_id, weekday, start_time)
class_teacher    (id, class_group_id → class_group, teacher_user_id → app_user, start_date, end_date NULL)
                  at most one open row per (class, teacher)
class_enrollment (id, student_id → student, class_group_id → class_group, start_date, end_date NULL)
                  at most one open row per student
```

- **History is never overwritten.** Moving a student closes the open `class_enrollment` row (its `end_date` becomes
  the move date) and inserts a new one. Removing a teacher closes their `class_teacher` row. Periods are half-open:
  a row covers `start_date` up to, not including, `end_date`.
- **Access.** A teacher's open `class_teacher` rows decide which classes, and therefore which students, they can see.
- **Search.** `search_name` is a stored, generated lower-case full name with a trigram (`pg_trgm`) index.
- **Deactivating a student** ends their current enrolment and sets `left_on`; nothing is deleted.

## Seed data

Development accounts are created by `DevDataSeeder` when the `dev` profile is active and the user table is empty.
They use fake names and the password from `DEV_SEED_PASSWORD`. `DevSchoolDataSeeder` then adds a fake school when
there are no students yet: 3 levels, 6 classes with a weekly slot and a teacher each, 30 students and 20 parents (8
with two or more children), and three students who moved class four weeks ago so class history is visible. Lessons
and the other modules' seed data are added with their phases.
