# API

Base path `/api`. JSON only. Every endpoint except login, refresh, logout and `GET /api/public/organisation` needs
`Authorization: Bearer <token>`. An account that still has a temporary password (new, or reset by an admin) has no
permissions until it sets its own password: only `/api/me` and `PUT /api/me/password` answer, everything else is
`403`.
With the `dev` profile the live OpenAPI document is at `/v3/api-docs` and Swagger UI at `/swagger-ui.html`.

## Phase 1 endpoints

| Method | Path | Permission | Purpose |
| --- | --- | --- | --- |
| POST | `/api/auth/login` | public | Email + password → access token, refresh token, user |
| POST | `/api/auth/refresh` | public (refresh token) | Rotate the refresh token, new access token |
| POST | `/api/auth/logout` | public (refresh token) | Revoke the refresh token |
| GET | `/api/public/organisation` | public | The mosque's name for the sign-in screen, and nothing else |
| GET | `/api/me` | signed in | Current user, roles and effective permissions |
| PUT | `/api/me/password` | signed in | Change own password; ends other sessions |
| GET | `/api/users?search=&role=&active=&page=&size=` | `USER_MANAGE` | List users |
| GET | `/api/users/{id}` | `USER_MANAGE` | One user |
| POST | `/api/users` | `USER_MANAGE` | Create a user; returns a one-time temporary password |
| PUT | `/api/users/{id}` | `USER_MANAGE` | Update name and email |
| PATCH | `/api/users/{id}/status` | `USER_MANAGE` | Activate or deactivate (ends their sessions) |
| PUT | `/api/users/{id}/roles` | `USER_MANAGE` | Replace roles (cannot remove your own ADMIN) |
| PUT | `/api/users/{id}/permissions` | `USER_MANAGE` | Replace extra permission grants, e.g. `PAYMENT_READ` for a teacher |

Only an ADMIN can give the ADMIN role or `USER_MANAGE`, `SETTINGS_MANAGE` or `AUDIT_READ`, or change an ADMIN's
account; anyone else with `USER_MANAGE` gets `403` for those.
| POST | `/api/users/{id}/password-reset` | `USER_MANAGE` | New temporary password; ends their sessions |
| GET | `/api/audit-log?entityType=&entityId=&userId=&from=&to=&page=&size=` | `AUDIT_READ` | Audit entries, newest first |

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

Lists return `{ "items": [...], "page": 0, "size": 25, "totalItems": 7 }`. The default page size is 25 and the
maximum 100; `/api/payments` defaults to 50 with a maximum of 200.

Permissions granted to a teacher one by one still stop at their own classes: `PARENT_READ` shows only the families
of children currently in their classes (and only those children); class management (`POST /api/classes`, changes
to a class, its teachers or timetable, `POST /api/curriculum-levels`) needs an admin role, so a teacher cannot add
themselves to another class; and a student can only be placed in a class the caller may see.

## Phase 3 endpoints

Lessons and attendance are scoped the same way: a teacher reaches only the lessons of the classes they are currently
assigned to, and any other id answers `404 NOT_FOUND`.

| Method | Path | Permission | Purpose |
| --- | --- | --- | --- |
| GET | `/api/lessons/today?date=` | `CLASS_READ` | The caller's day: lessons already opened plus the scheduled slots that are not. A slot has `"id": null` until it is opened |
| GET | `/api/lessons?classId=&from=&to=&page=&size=` | `CLASS_READ` | Lessons, newest first |
| GET | `/api/lessons/{id}` | `CLASS_READ` | The lesson with its register, that week's curriculum topics and the topics covered |
| POST | `/api/lessons` | `LESSON_RECORD` | Open a lesson for a class and date, from a `classScheduleId` or with explicit times. Idempotent: opening the same slot twice returns the same lesson. A future date is refused |
| PUT | `/api/lessons/{id}` | `LESSON_RECORD` | What was taught: `contentNotes`, `status` (`PLANNED`/`COMPLETED`/`CANCELLED`) and `coveredTopicIds`, which must belong to that class's current period |
| PUT | `/api/lessons/{id}/attendance` | `LESSON_RECORD` | The whole register in one request. `LATE` requires `minutesLate`, only `ABSENT` may carry an `absenceReason`, and a student who is not in the class is refused |
| GET | `/api/attendance?studentId=&from=&to=` | `STUDENT_READ` | One student's attendance history |
| GET | `/api/attendance/statistics?studentId=&from=&to=` | `STUDENT_READ` | Counts and `attendancePercentage` (present and late count as attended), with the organisation's threshold. Calculated per request, never stored |
| GET | `/api/curriculum/periods?levelId=` | `CURRICULUM_READ` | Four-week periods |
| GET | `/api/curriculum/periods/current?levelId=` | `CURRICULUM_READ` | The period covering today, with its weeks and topics |
| GET | `/api/curriculum/periods/{id}` | `CURRICULUM_READ` | One period with its weeks and topics |
| POST, PUT | `/api/curriculum/periods`, `/api/curriculum/periods/{id}` | `CURRICULUM_WRITE` | Create or update a period with its four weeks and their topics. The end date follows from the start date; overlapping periods of one level are refused |

## Phase 4 endpoints

Progress, behaviour and uniform are recorded per lesson and use the lesson's scope: an id outside the caller's
classes answers `404 NOT_FOUND`, and a student who is not in the lesson's class now is refused with `400`. Each
`PUT` sends the whole picture (for progress: of one subject), so a student left out no longer has a record.

| Method | Path | Permission | Purpose |
| --- | --- | --- | --- |
| GET | `/api/progress/scale` | signed in | The organisation's progress scale, lowest first: `{score, label}` (2 Low, 3 Medium, 3.5 Almost Good, 4 Good, 4.5 Very Good, 5 Excellent) |
| GET, PUT | `/api/lessons/{id}/progress` | `CLASS_READ`, `PROGRESS_RECORD` | Every score in the lesson; a `PUT` sends `{subject, entries: [{studentId, score, note}]}` and a score off the scale is refused |
| GET | `/api/progress?studentId=` | `STUDENT_READ` | A student's scores with lesson date, class, subject and label, newest first |
| GET, PUT | `/api/lessons/{id}/behaviour` | `CLASS_READ`, `OBSERVATION_RECORD` | Observations in the lesson: `{studentId, behaviours: [...], note}`; any number of behaviours each, and an entry with nothing selected and no note removes that student's observation |
| GET | `/api/behaviour?studentId=` | `STUDENT_READ` | A student's observations, each with its lesson date |
| GET, PUT | `/api/lessons/{id}/uniform` | `CLASS_READ`, `OBSERVATION_RECORD` | Uniform in the lesson: `{studentId, status, reason, note}`; `IN_ORDER` may not carry a reason |
| GET | `/api/uniform?studentId=` | `STUDENT_READ` | A student's uniform records, each with its lesson date |
| GET | `/api/targets?studentId=` | `STUDENT_READ` | All of a student's targets, the latest period first, each with its period |
| POST | `/api/targets` | `TARGET_MANAGE` | `{studentId, curriculumPeriodId, subject?, description, targetPercentage?, currentPercentage?, progressScore?, teacherNote?}`. The period must belong to the level of the student's current class; percentages are 0 to 100 and the score must be on the scale |
| PUT | `/api/targets/{id}` | `TARGET_MANAGE` | Update what can change; the student and period stay as they were. Another teacher's target answers `404` |
| GET | `/api/progress/classes/{classId}` | `CLASS_READ` | The class at a glance: the period running today, and per student their latest score in that period and their targets for it |

Targets are never deleted, so the targets of earlier periods stay available.

Behaviour values: `GOOD_QURAN_RECITATION`, `LEARNED_ISLAMIC_STUDIES`, `LEARNED_NAMAZ_AND_DUAS`,
`LEARNED_NAAT_OR_SPEECH`, `LISTENED_TO_TEACHER`, `BEEN_HELPFUL`, `ORGANISED`, `RESPECTFUL`, `GOOD_GROUP_WORK`,
`USING_TIME_EFFECTIVELY` (good) and `OFF_TASK`, `NOT_LISTENING`, `DISTRACTING`, `TALKING`, `DISORGANISED`,
`LACK_OF_EFFORT`, `WASTING_TIME`, `SHOUTING`, `WALKING_OR_RUNNING_AROUND` (needs attention). Uniform statuses:
`IN_ORDER`, `PARTIALLY_IN_ORDER`, `NOT_IN_ORDER`; reasons: `HIJAB_MISSING`, `SHIRT_NOT_ACCORDING_TO_UNIFORM`, `OTHER`.

## Phase 5 endpoints

Payments follow the student scope: someone who sees only some classes (a teacher granted `PAYMENT_READ`) sees
only their own students' payments, and month totals count only those students. Adding a month and changing its
fee affect every student, so they need access to every class (`403` otherwise). Amounts are in the
organisation's currency, which every response carries as `currency`.

| Method | Path | Permission | Purpose |
| --- | --- | --- | --- |
| GET | `/api/payment-periods` | `PAYMENT_READ` | Every month, the latest first: `{id, month: "2026-10", monthlyFee, currency, totals}` with `totals` = `{students, paid, partiallyPaid, outstanding, expectedTotal, paidTotal, outstandingTotal}` |
| GET | `/api/payment-periods/{id}` | `PAYMENT_READ` | One month with its totals |
| POST | `/api/payment-periods` | `PAYMENT_WRITE` | `{month, monthlyFee}` adds a month and charges every student enrolled during it; `409` if the month exists |
| PUT | `/api/payment-periods/{id}` | `PAYMENT_WRITE` | `{monthlyFee}`: students still on the old fee move to the new one; refused when one of them already paid more than the new fee |
| POST | `/api/payment-periods/{id}/payments` | `PAYMENT_WRITE` | Adds students who joined after the month was added: `{added, period}`. Safe to repeat |
| GET | `/api/payments?periodId=&studentId=&status=&classId=&search=&page=&size=` | `PAYMENT_READ` | Payments, newest month first then by name: `{id, periodId, month, studentId, firstName, lastName, className, payer, expectedAmount, amountPaid, outstandingAmount, currency, status, paidOn, method, note}` |
| PUT | `/api/payments/{id}` | `PAYMENT_WRITE` | `{expectedAmount, amountPaid, paidOn, method, parentGuardianId, note}`. `amountPaid` is the month's total and may not exceed `expectedAmount`; above zero it needs a date (not in the future) and a method; the payer must be one of the student's parents |
| DELETE | `/api/payments/{id}` | `PAYMENT_WRITE` | Takes a student off a month; `409` once anything has been paid |

Statuses (`PAID`, `PARTIALLY_PAID`, `OUTSTANDING`) are worked out from the amounts. Methods: `CASH`,
`BANK_TRANSFER`, `CARD`, `OTHER`. Changes are audited as `PAYMENT_PERIOD_CREATED`, `PAYMENT_PERIOD_UPDATED`,
`PAYMENT_UPDATED` and `PAYMENT_REMOVED`, with amounts but without the note.

## Phase 6 endpoints

Reports are read-only and calculated on request; nothing is stored. Every report counts only the classes the caller
may see: a lesson belongs to the class it was given in, so a teacher's reports cover the lessons of their own
classes, and a `classId` outside their classes is `404`. Without `from` and `to` a report covers the last four
weeks, today included; `from` must be on or before `to`, and the range may be at most a year (`400` otherwise).
Attendance percentages count present and late as attended and are `null` when no register was taken.

| Method | Path | Permission | Purpose |
| --- | --- | --- | --- |
| GET | `/api/reports/dashboard` | `REPORT_READ` | The dashboard figures: `attendance` of the last four weeks `{from, to, attendancePercentage, late, absent, studentsBelowThreshold, thresholdPercentage}`, `progress` `{targets, targetsBehind}` in the periods running now, and `payments` `{month, currency, totals}` for the latest month up to now (`null` without `PAYMENT_READ`) |
| GET | `/api/reports/attendance?from=&to=&classId=` | `REPORT_READ` | `{from, to, thresholdPercentage, totals, absenceReasons: {SICK: 2, …}, classes: [{classId, className, counts}], belowThreshold: [{studentId, firstName, lastName, classId, className, counts}]}` with `counts` = `{lessons, records, present, late, absent, attendancePercentage}`; students lowest first |
| GET | `/api/reports/progress?classId=` | `REPORT_READ` | Per active class the period running now, `students`, `scores`, `averageScore` (one decimal, all subjects), `targets` and `targetsBehind`; `behindTarget` lists every target whose current percentage is below the target percentage. With `classId`, `periods` gives the class's average per period for its last six periods |
| GET | `/api/reports/behaviour?from=&to=&classId=` | `REPORT_READ` | `{from, to, observations, behaviours: [{behaviour, good, count}], recurringAtLeast: 3, recurring: [{studentId, firstName, lastName, className, behaviour, count, lastSeen}]}`; `recurring` lists a behaviour that needs attention seen three times or more for one student |
| GET | `/api/reports/payments` | `REPORT_READ` and `PAYMENT_READ` | The last twelve months up to now `{currency, months, totals, studentsOwing: [{studentId, firstName, lastName, className, months, outstandingAmount}]}`, most owed first |
| GET | `/api/reports/students/{id}?from=&to=` | `REPORT_READ` | One student: `attendance` with absence reasons, `progress` per subject (average, latest score and label), the `targets` of periods overlapping the range, `behaviour` counts, `uniform` `{inOrder, partiallyInOrder, notInOrder}`, and `payments` `{currency, months, monthsOwing, expectedTotal, paidTotal, outstandingTotal}` only for callers with `PAYMENT_READ`. `404` outside the caller's classes |

## Permissions per role

| Permission | ADMIN | ADMINISTRATOR | TEACHER |
| --- | --- | --- | --- |
| `USER_MANAGE`, `SETTINGS_MANAGE`, `AUDIT_READ` | yes | no | no |

`SETTINGS_MANAGE` is reserved: no endpoint uses it yet, because the mosque's settings have no API so far.
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
