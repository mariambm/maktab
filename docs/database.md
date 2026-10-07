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
| `V8__curriculum.sql` | `curriculum_period`, `curriculum_week`, `lesson_topic` |
| `V9__lessons_and_attendance.sql` | `lesson`, `lesson_topic_covered`, `lesson_attendance` |
| `V10__mosque_settings_and_subjects.sql` | The organisation becomes Jamiyat Tabligh UL Islam (GBP, Europe/London); the mosque's own absence reasons; `lesson_topic.subject` |
| `V11__progress_behaviour_uniform.sql` | `progress_scale_level` (seeded with the mosque's scale), `student_progress`, `behaviour_record`, `behaviour_record_item`, `uniform_record` |
| `V12__student_targets.sql` | `student_target` |

Planned: payments.

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

## Phase 3 tables

```text
curriculum_period     (id, organisation_id, curriculum_level_id → curriculum_level, number, name,
                       start_date, end_date)
                       CHECK end_date = start_date + 27 (four weeks);  UNIQUE (curriculum_level_id, number)
curriculum_week       (id, curriculum_period_id → curriculum_period, week_number 1..4, is_review)
                       UNIQUE (curriculum_period_id, week_number)
lesson_topic          (id, curriculum_week_id → curriculum_week, subject NULL ∈ QURAN_RECITATION|ISLAMIC_STUDIES|
                       NAMAZ_AND_DUAS|ARABIC|NAATS_AND_SPEECHES, title, learning_objective NULL, sort_order)
lesson                (id, class_group_id → class_group, class_schedule_id NULL → class_schedule
                       (ON DELETE SET NULL), lesson_date, start_time, end_time, teacher_user_id → app_user,
                       content_notes NULL, status ∈ PLANNED|COMPLETED|CANCELLED)
                       CHECK end_time > start_time;  UNIQUE (class_group_id, lesson_date, start_time)
lesson_topic_covered  (lesson_id → lesson, lesson_topic_id → lesson_topic)   PK (lesson_id, lesson_topic_id)
lesson_attendance     (id, lesson_id → lesson, student_id → student, status ∈ PRESENT|LATE|ABSENT,
                       minutes_late NULL 1..300, absence_reason NULL ∈ AUTHORISED|UNAUTHORISED|SICK|HOLIDAY|NOT_READING,
                       note NULL, recorded_by → app_user, …)
                       UNIQUE (lesson_id, student_id)
                       CHECK (status = LATE) = (minutes_late IS NOT NULL)
                       CHECK status = ABSENT OR absence_reason IS NULL
```

- **A period is always four weeks**, and week 4 is the review week. The end date follows from the start date, so it
  is derived rather than entered, and periods of one level may not overlap.
- **Nothing calculated is stored.** Attendance percentages and absence or lateness counts are counted from
  `lesson_attendance` on every request, so a corrected lesson is reflected at once.
- **One lesson per class, date and start time**, so opening a lesson twice returns the same one instead of creating a
  duplicate register.
- **Subjects.** Every topic belongs to one subject of the mosque's teaching list. The column is nullable only for
  topics written before subjects existed; the API requires a subject for every topic it saves.
- **Absence reasons** are the mosque's own. A reason is optional and never guessed by the app.
- **Observations are per lesson**, never a permanent label on a child: every attendance row belongs to one lesson on
  one date.

## Phase 4 tables

```text
progress_scale_level  (organisation_id → organisation, score numeric(2,1), label)   PK (organisation_id, score)
student_progress      (id, lesson_id → lesson, student_id → student, subject, score numeric(2,1), note NULL,
                       recorded_by → app_user, …)
                       UNIQUE (lesson_id, student_id, subject)
behaviour_record      (id, lesson_id → lesson, student_id → student, note NULL, recorded_by → app_user, …)
                       UNIQUE (lesson_id, student_id)
behaviour_record_item (behaviour_record_id → behaviour_record ON DELETE CASCADE, behaviour)
                       PK (behaviour_record_id, behaviour)
uniform_record        (id, lesson_id → lesson, student_id → student,
                       status ∈ IN_ORDER|PARTIALLY_IN_ORDER|NOT_IN_ORDER,
                       reason NULL ∈ HIJAB_MISSING|SHIRT_NOT_ACCORDING_TO_UNIFORM|OTHER, note NULL,
                       recorded_by → app_user, …)
                       UNIQUE (lesson_id, student_id);  CHECK status <> IN_ORDER OR reason IS NULL
student_target        (id, student_id → student, curriculum_period_id → curriculum_period, subject NULL,
                       description, target_percentage NULL 0..100, current_percentage NULL 0..100,
                       progress_score NULL, teacher_note NULL, created_by, updated_by → app_user, …)
```

- **One scale for every subject**, as the mosque decided: 2 Low, 3 Medium, 3.5 Almost Good, 4 Good, 4.5 Very Good,
  5 Excellent. The labels live in `progress_scale_level`, not in code, so they can change without a release; the API
  refuses a score that is not on the scale.
- **Everything is tied to a lesson**, and so to a date: a score, an observation or a uniform note is about that day,
  never a lasting label on the child. A student's history is read by joining `lesson`.
- **Targets belong to a four-week period**, which is fixed once the target exists, so a student's targets of
  earlier periods stay as they were. A new target must use a period of the student's current level.
- **Several behaviours per observation**: one `behaviour_record` per student per lesson, with its behaviours in
  `behaviour_record_item`.

## Seed data

Development accounts are created by `DevDataSeeder` when the `dev` profile is active and the user table is empty.
They use fake names and the password from `DEV_SEED_PASSWORD`. `DevSchoolDataSeeder` then adds a fake school when
there are no students yet: 3 levels, 6 classes with a weekly slot and a teacher each, 30 students and 20 parents (8
with two or more children), and three students who moved class four weeks ago so class history is visible.
`DevTeachingDataSeeder` then adds two four-week curriculum periods per level with a topic per week, and eight weeks
of past lessons with attendance; today's lesson is deliberately left unopened so the teacher's day has something to
do. `DevDevelopmentDataSeeder` adds a Quran Recitation score for every student who attended a seeded lesson, plus
some behaviour observations and uniform notes, and a target in the current period for some students. Seed data for the other modules is added with their phases.
