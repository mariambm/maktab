# Architecture

The full proposal, with diagrams, the domain model and the decisions that were confirmed, is the
[Maktab architecture proposal](https://claude.ai/code/artifact/11fde2d7-2319-4e1f-aa08-a0e8a283603c). This file records
what is built and anything that differs from the proposal.

## Overview

One Spring Boot service (a modular monolith) talks to one PostgreSQL database. The Flutter app talks only to the REST
API over HTTPS, authenticated with a JWT. Docker Compose runs PostgreSQL and the backend for local development.

## Confirmed decisions (2026-10-07)

1. Monorepo: `backend/`, `frontend/`, `docs/`.
2. Organisation-ready schema: `organisation_id` on top-level tables, one organisation seeded.
3. ADMIN manages users, roles, permissions, settings and the audit log; ADMINISTRATOR runs day-to-day operations.
4. 15-minute access tokens plus 30-day rotating refresh tokens.
5. Android and iOS first; web administration later.
6. Europe/Amsterdam time zone and EUR currency as organisation settings.
7. Teachers see only their assigned classes (enforced from Phase 2); payment access can be granted per user.

## Backend modules (`com.maktab`)

Each module has the same shape: `api/` (controllers, request/response DTOs), `application/` (services, business rules,
authorisation), `domain/` (JPA entities, enums), `persistence/` (Spring Data repositories). Entities never leave the
service layer.

| Module | Phase 1 contents |
| --- | --- |
| `auth` | Login, refresh, logout, `/api/me`, password change, access and refresh tokens, login throttling, JWT-to-user conversion |
| `user` | Users, roles, permissions (`RolePermissions`), user administration API |
| `audit` | Audit log writer (`AuditService`) and read API |
| `organisation` | The organisation entity |
| `common` | Error format and handler, correlation id filter, paging |
| `config` | Security, CORS, OpenAPI, clock |
| `student` | Students, parent links, class moves (Phase 2) |
| `parent` | Parents and guardians (Phase 2) |
| `classgroup` | Curriculum levels, classes, weekly schedules, teacher assignments, enrolments, `AccessScopeService` (Phase 2) |
| `dev` | Development seed accounts and fake school data (`dev` profile only) |

Modules for lessons, attendance, curriculum, progress, behaviour, uniform, payments and reports are added in their
phases.

## Authentication and authorisation

- `POST /api/auth/login` returns a 15-minute HS256 JWT and a 30-day opaque refresh token. Only a SHA-256 hash of the
  refresh token is stored. Each refresh rotates it; presenting an already-rotated token revokes the whole session
  family.
- On every request the JWT subject is loaded from the database (`CurrentUserJwtConverter`), so deactivation and
  permission changes take effect immediately. Authorities are the user's permissions plus `ROLE_<role>`.
- Endpoints declare `@PreAuthorize("hasAuthority('…')")`. `EndpointSecurityCoverageTest` fails if any endpoint does
  not.
- Lookups are scoped to the caller's organisation; out-of-scope ids return 404.
- Student and class reads are also scoped by `AccessScope`: everything for ADMIN and ADMINISTRATOR, otherwise the
  classes with an open `class_teacher` row for the caller. The scope is a query parameter, so filtering happens in
  SQL. Changing an id in a request therefore cannot reach another teacher's students.
- Five failed logins for an email within 15 minutes lock it for 15 minutes (HTTP 429).

## Differences from the proposal

| Proposal | Built | Why |
| --- | --- | --- |
| Bucket4j for login rate limiting | A small in-memory `LoginAttemptService` | One backend instance needs no library; move to the database if the backend is scaled out |
| `freezed` for Flutter models | `json_serializable` only | Phase 1 models are small; `freezed` can be added when models need copy/equality |
| Spring Boot "current GA" | Spring Boot 4.1.1, Java 21 | Latest stable at Phase 1 start |
| Teachers read classes through their existing permissions | New `CLASS_READ` permission (all roles) | Reading a class list is not "student" data; a clear permission keeps `CLASS_MANAGE` for changes only |
| Optional Excel import of students in Phase 2 | Not built | Waits for a sample export of the current spreadsheet (fake or redacted data) |
| `/api/students/{id}/summary` and per-module tabs | Profile shows details, class history and parents | Attendance, progress and observations arrive in Phases 3 and 4 |

## Flutter app (`frontend/lib`)

- `core/api`: Dio with `AuthInterceptor` (adds the token, refreshes once on 401, retries).
- `core/auth`: `AuthRepository`, `SessionController` (Riverpod), `TokenStorage` (access token in memory, refresh token
  in secure storage).
- `core/routing`: go_router, `resolveRedirect` (signed-out → login, temporary password → change password, unpermitted
  module → dashboard) and `destinations.dart` (role-aware navigation).
- `core/theme`: the Maktab design system on Material 3.
- `core/widgets`: `AsyncView` (loading, empty, error with retry), `MaktabShell` (bottom bar or rail), shared views.
- `features/*`: one folder per module with `data/` and `presentation/`.
- All user-facing strings are in `lib/l10n/app_en.arb`.

## Roadmap

1. **Foundation** (done)
2. **Administration** (done): students, parents, classes, class enrolments
3. Teaching: curriculum, lessons, attendance, Today's lessons
4. Student development: progress, targets, behaviour, uniform
5. Finance: payment periods, payments
6. Reporting: dashboards and reports
7. Quality: security, permission, performance, UX and accessibility reviews
