# API

Base path `/api`. JSON only. Every endpoint except login, refresh and logout needs `Authorization: Bearer <token>`.
With the `dev` profile the live OpenAPI document is at `/v3/api-docs` and Swagger UI at `/swagger-ui.html`.

## Phase 1 endpoints

| Method | Path | Permission | Purpose |
| --- | --- | --- | --- |
| POST | `/api/auth/login` | public | Email + password → access token, refresh token, user |
| POST | `/api/auth/refresh` | public (refresh token) | Rotate the refresh token, new access token |
| POST | `/api/auth/logout` | public (refresh token) | Revoke the refresh token |
| GET | `/api/me` | signed in | Current user, roles and effective permissions |
| PUT | `/api/me/password` | signed in | Change own password; ends other sessions |
| GET | `/api/users?search=&role=&active=&page=&size=` | `USER_MANAGE` | List users |
| GET | `/api/users/{id}` | `USER_MANAGE` | One user |
| POST | `/api/users` | `USER_MANAGE` | Create a user; returns a one-time temporary password |
| PUT | `/api/users/{id}` | `USER_MANAGE` | Update name and email |
| PATCH | `/api/users/{id}/status` | `USER_MANAGE` | Activate or deactivate (ends their sessions) |
| PUT | `/api/users/{id}/roles` | `USER_MANAGE` | Replace roles (cannot remove your own ADMIN) |
| PUT | `/api/users/{id}/permissions` | `USER_MANAGE` | Replace extra permission grants, e.g. `PAYMENT_READ` for a teacher |
| POST | `/api/users/{id}/password-reset` | `USER_MANAGE` | New temporary password; ends their sessions |
| GET | `/api/audit-log?entityType=&entityId=&userId=&from=&to=` | `AUDIT_READ` | Audit entries, newest first |

## Phase 2 endpoints

Reads of students and classes are scoped: ADMIN and ADMINISTRATOR see everything, a teacher sees only the classes
they are currently assigned to and the students currently in them. Any other id answers `404 NOT_FOUND`.

| Method | Path | Permission | Purpose |
| --- | --- | --- | --- |
| GET | `/api/students?search=&classId=&status=&page=&size=` | `STUDENT_READ` | Students with their current class |
| GET | `/api/students/{id}` | `STUDENT_READ` | Profile: details, current class, parents (without `PARENT_READ`: primary contact's name and phone only) |
| POST | `/api/students` | `STUDENT_WRITE` | Create; optional `classId` and `parents` in the same request |
| PUT | `/api/students/{id}` | `STUDENT_WRITE` | Update personal details |
| PATCH | `/api/students/{id}/status` | `STUDENT_WRITE` | `ACTIVE` / `INACTIVE`; deactivating ends the current class today |
| PUT | `/api/students/{id}/parents` | `STUDENT_WRITE` + `PARENT_READ` | Replace parent links (one primary contact; the first is primary if none is chosen) |
| GET | `/api/students/{id}/enrollments` | `STUDENT_READ` | Class history, newest first |
| POST | `/api/students/{id}/enrollments` | `STUDENT_WRITE` | Move to a class from `startDate` (default today); closes the current class |
| DELETE | `/api/students/{id}/enrollments/current` | `STUDENT_WRITE` | Take the student out of their class today |
| GET | `/api/parents?search=&page=&size=` | `PARENT_READ` | Search by name, phone or email; each with their children |
| GET | `/api/parents/{id}` | `PARENT_READ` | One parent/guardian with children |
| POST, PUT | `/api/parents`, `/api/parents/{id}` | `PARENT_WRITE` | Create, update |
| GET | `/api/classes?search=&levelId=&active=&page=&size=` | `CLASS_READ` | Classes with level, teachers, schedule and student count |
| GET | `/api/classes/{id}` | `CLASS_READ` | One class |
| GET | `/api/classes/{id}/students` | `CLASS_READ` + `STUDENT_READ` | Students in the class now |
| POST, PUT | `/api/classes`, `/api/classes/{id}` | `CLASS_MANAGE` | Create, update (a class with students cannot be deactivated) |
| PUT | `/api/classes/{id}/teachers` | `CLASS_MANAGE` | Replace current teachers (`teacherIds`); removed assignments end today |
| PUT | `/api/classes/{id}/schedule` | `CLASS_MANAGE` | Replace weekly slots (`weekday`, `startTime`, `endTime`) |
| GET | `/api/curriculum-levels` | `CLASS_READ` | Levels in order |
| POST | `/api/curriculum-levels` | `CLASS_MANAGE` | Create a level |
| GET | `/api/teachers` | `CLASS_MANAGE` | Active teachers to assign |

Lists return `{ "items": [...], "page": 0, "size": 25, "totalItems": 7 }`.

## Permissions per role

| Permission | ADMIN | ADMINISTRATOR | TEACHER |
| --- | --- | --- | --- |
| `USER_MANAGE`, `SETTINGS_MANAGE`, `AUDIT_READ` | yes | no | no |
| `STUDENT_READ`, `CLASS_READ` | yes | yes | yes (assigned classes only) |
| `STUDENT_WRITE`, `PARENT_READ`, `PARENT_WRITE`, `CLASS_MANAGE`, `CURRICULUM_WRITE` | yes | yes | no |
| `CURRICULUM_READ`, `LESSON_RECORD`, `PROGRESS_RECORD`, `TARGET_MANAGE`, `OBSERVATION_RECORD`, `REPORT_READ` | yes | yes | yes |
| `PAYMENT_READ`, `PAYMENT_WRITE` | yes | yes | no, unless granted to that user |

## Errors

```json
{
  "timestamp": "2026-10-07T09:46:10Z",
  "status": 400,
  "error": "VALIDATION_ERROR",
  "message": "Validation failed",
  "path": "/api/users",
  "correlationId": "8f1c2a0d",
  "fieldErrors": { "firstName": "First name is required" }
}
```

| Status | `error` |
| --- | --- |
| 400 | `VALIDATION_ERROR`, `MALFORMED_REQUEST` |
| 401 | `UNAUTHENTICATED` |
| 403 | `FORBIDDEN` |
| 404 | `NOT_FOUND` (also for records outside your scope) |
| 405 | `METHOD_NOT_ALLOWED` |
| 409 | `CONFLICT` |
| 429 | `TOO_MANY_REQUESTS` |
| 500 | `INTERNAL_ERROR` (generic message; details only in the server log under the correlation id) |
