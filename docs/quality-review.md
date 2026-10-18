# Quality review (Phase 7)

Reviewed on 2026-10-18 against `main` after Phase 6. Seven areas were reviewed: security, permissions, testing,
performance, UX, accessibility and documentation. Each finding below was checked against the code by following a real
request or screen. The fixes are in the Phase 7 pull request; the open points are listed at the end with a
recommendation.

## What held up

- **Authentication**
  - BCrypt with cost 12, and the same response time for unknown emails.
  - Login throttling.
  - The JWT secret comes only from the environment and must be at least 32 bytes.
  - Refresh tokens are stored hashed, rotate on every use, and a reused token revokes its whole session.
  - Deactivation and permission changes take effect on the next request, because the user is reloaded every time.
- **Errors and logs**
  - Every error uses the same JSON shape, with a correlation id and no stack trace.
  - No passwords, tokens or hashes appear in logs, responses or the audit log.
  - `.env` is git-ignored, and only placeholders are committed.
- **Data scope**
  - Every id in a path, query or body is checked against the caller's classes, in SQL, so an out-of-scope id gives
    404.
  - A teacher with default permissions cannot reach another class by changing an id.
  - Payment data appears only with `PAYMENT_READ`.
- **Performance**
  - Lists are paged, open-session-in-view is off, and the lookups behind a page are batched.
  - Every filtered column has an index.
- **App states**
  - Every screen has loading, empty and error states with a retry.
  - Every save shows a confirmation.
  - Every icon button has a tooltip.
  - Status is always shown with text and an icon.

## Fixed in this phase

### Security and permissions

| Finding | Fix |
| --- | --- |
| A temporary password (new account or admin reset) was only forced to change in the app; the API worked with it indefinitely | Until the password is changed, the account has no permissions on the server: only `/api/me` and `PUT /api/me/password` answer |
| A teacher granted `PARENT_READ` saw every family in the mosque, including children in other classes | Teachers see only the families of children currently in their classes, and only those children |
| A teacher granted `CLASS_MANAGE` could assign themselves to another teacher's class and then see its students | Changing classes, their teachers or timetable, and creating classes or levels needs an admin role |
| A teacher granted `STUDENT_WRITE` could place a student in any class | The new class must be one the caller may see |
| A user with `USER_MANAGE` who is not ADMIN could make themselves ADMIN, or reset an admin's password | Only an ADMIN can give admin rights or change an ADMIN account |
| Two refreshes with the same token at the same moment could both succeed, so reuse went unnoticed | The token row is locked during rotation |
| Lesson lookups did not check the organisation (latent until a second mosque is added) | Lesson queries now filter on the class's organisation |
| A wrong content type, such as `text/plain` on login, gave a 500 and an error log entry with a stack trace | It is now a 400 `MALFORMED_REQUEST`, logged only at debug level |
| The lesson list failed on PostgreSQL when `from`/`to` were given (the same parameter-type issue fixed in Phase 6) | Fixed and covered by a test |

### Performance

- Behaviour records and user roles were loaded with one query per row: about 150 queries for a student profile with
  three years of history.
- `hibernate.default_batch_fetch_size: 100` now loads them in batches.

### UX and accessibility

| Finding | Fix |
| --- | --- |
| If today's lessons failed to load, the dashboard showed a spinner forever | It now shows the error with **Try again** |
| The dashboard's **Open** button went to the Lessons list instead of the lesson | It opens the lesson directly |
| Opening a lesson gave no visible feedback | A progress bar shows while the lesson opens |
| Switching subject in Progress threw away unsaved scores | Scores for each subject are kept until saved |
| A note on a student set back to Present was hidden but still saved | The note is cleared |
| Report attendance chips had a contrast of 2.9:1 and 3.8:1 | They use darker text, now 6.2:1 and 5.7:1 |
| Sidebar items were 44 px high | They are now at least 48 px |
| The top bar and the compact sign-in header had fixed heights that clipped large text | They now use a minimum height and grow with the text |
| Empty and error screens could not be pulled to refresh | They now can |
| Curriculum create and edit screens opened for users without `CURRICULUM_WRITE` (the server already refused the save) | These routes now redirect such users away |

### Tests and documentation

- **New backend tests** (97 → 105):
  - temporary-password lockdown;
  - password reset;
  - user managers cannot grant admin rights;
  - granted permissions stay within the teacher's classes (parents, class management, enrolment);
  - lesson list date filters;
  - a wrong content type gives a 400.
- **New Flutter tests** (96 → 98):
  - the dashboard error state;
  - curriculum routes are guarded;
  - setting a student to Present clears their note.
- **Documentation fixes**:
  - The API docs now name the public mosque-name endpoint, the paging limits and the scope rules for granted
    permissions, and say that `SETTINGS_MANAGE` is reserved.
  - The database docs now include the missing check constraints, and `organisation_id` is removed from
    `curriculum_period`, which does not have that column.
  - The README now lists everything the dev seed creates.
  - Stale Phase 1 text is gone.

## Open points (not fixed here)

### Recommended next

1. **One save for the whole lesson.** The lesson screen has five separate save buttons (attendance, topic, progress,
   behaviour, uniform), and leaving the screen gives no warning about unsaved changes.
   - **Risk:** this is the most likely way for a teacher to lose work.
   - **Proposal:** one **Save lesson** button that saves every changed section, plus a warning when leaving with
     unsaved changes.
   - This changes the main teacher workflow, so it needs your go-ahead.
2. **Faster saves.** Every new row first runs a SELECT before its INSERT, because ids are assigned in the
   constructor. Two places where this adds up:
   - a register of 25 students: 50 queries;
   - opening a month of fees for 300 students: 600 queries.
   - **Fix:** switch the entities' `version` fields to `Long` and turn on JDBC batching. This touches every entity, so
     it deserves its own change.
3. **Progress report and dashboard queries.** These run about 4 to 5 queries per class: around 100 for 20 classes.
   They can be grouped into a few queries.

### Worth doing later

- **Login throttling.**
  - It counts per email only and never forgets unknown emails.
  - **Fix:** add a per-IP limit and an expiring cache.
- **Tokens after a password change.**
  - An access token stays valid for up to 15 minutes after a password change or reset.
  - **Fix:** store when the password last changed and reject older tokens.
- **Audit log gaps.** Logout and refresh-token reuse are not written to the audit log.
- **Reports name students who left a class.**
  - The attendance and behaviour reports still list a student who has left a teacher's class, for lessons that
    teacher gave.
  - This is defensible, because the teacher took those registers, but their current class name could be hidden.
- **Student history is unbounded.** The student profile loads the full attendance, progress, behaviour and uniform
  history. Paging, or a default of the last 12 months, will matter after a few years.
- **The month view of fees.**
  - It loads up to 200 rows at once and reloads them all after every edit.
  - **Fix:** a lazily built list with a "load more" button.
- **Docker defaults.**
  - Docker Compose defaults to the `dev` profile, and the dev seed accepts any password.
  - Fine on a laptop, but a server needs an explicit profile and a strong seed password.
- **Test coverage gaps.**
  - Services and repositories are tested end to end only; there are no isolated tests of those layers.
  - The Flutter app has no tests for these screens: classes, parents list, change password, student profile and
    curriculum form.
