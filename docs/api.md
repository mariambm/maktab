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

Lists return `{ "items": [...], "page": 0, "size": 25, "totalItems": 7 }`.

## Permissions per role

| Permission | ADMIN | ADMINISTRATOR | TEACHER |
| --- | --- | --- | --- |
| `USER_MANAGE`, `SETTINGS_MANAGE`, `AUDIT_READ` | yes | no | no |
| `STUDENT_READ` | yes | yes | yes (assigned classes, from Phase 2) |
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
