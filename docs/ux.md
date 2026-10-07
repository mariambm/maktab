# UX

## Principles

- The teacher workflow comes first: open Maktab, see today's lessons, register attendance, record the lesson, save.
  A normal register should take about a minute.
- Never ask for information the system already knows.
- Every screen has loading, empty, error-with-retry, validation and success states (`AsyncView`, `MessageView`).
- Touch targets are at least 48 dp. Status is shown with text and icon, never colour alone.
- All user-facing text is English and lives in `lib/l10n/app_en.arb`.

## Design system

Material 3 with `MaktabTheme.light()`:

| Token | Value |
| --- | --- |
| Primary (deep teal) | `#0F5B5B` |
| Primary dark | `#0A4242` |
| Accent (gold, sparingly) | `#B8913A` |
| Background (soft neutral) | `#F6F5F1` |
| Surface | white |
| Outline | `#DCD9D0` |
| Corner radius | 12 |
| Spacing scale | 4, 8, 16, 24, 32 |

The only decorative Islamic motif is a faint eight-pointed star pattern behind the logo on the login screen.

## Navigation

Phones: a bottom bar with four role-specific destinations plus "More". Wide screens (≥ 840 px): a navigation rail
with every permitted destination.

| Role | Bottom bar |
| --- | --- |
| Teacher | Dashboard, Lessons, Students, Progress |
| Admin / Administrator | Dashboard, Students, Classes, Payments |

Teachers never see Payments or Parents & Guardians unless an admin grants them the permission. Opening a hidden
module by URL redirects to the dashboard, and the backend refuses the data regardless.

## Phase 1 screens

Login, change password (forced after a temporary password), dashboard (greeting and what will appear), settings
(account, change password, sign out, Users & Permissions for ADMIN), a users list, and placeholders for
modules built in later phases.

## Phase 2 screens

- **Students Overview**: search (as you type, debounced), class filter, Active / Inactive / All. Each row shows the
  class and age. Administrators get an "Add Student" button.
- **Add Student**: name, date of birth (year picker first), optional gender, join date (today by default), class and
  parents in the same form. A new parent can be created from the picker without leaving the form; the family name is
  pre-filled from the student.
- **Student Profile**: personal information, class with full history ("Move to another class" asks only for the new
  class and date), and parents. Teachers see the primary contact's name and phone only. Deactivate / Reactivate and
  "Remove from class" are in the overflow menu and ask for confirmation.
- **Parents & Guardians**: search by name, phone or email; detail shows contact details and children.
- **Classes Overview** and **class detail**: level, room, weekly schedule, teachers and the current students.
  Administrators edit everything about a class, including teachers and schedule, in one form.
- **Users & Permissions** (ADMIN only, under Settings): search accounts and add one with name, email and roles. The
  temporary password is shown once in a dialog with a copy button; the person must choose their own at first sign-in.
  A user's page shows status, last sign-in, roles and extra permissions (each edited in a sheet; permissions a role
  already gives are shown ticked and locked), plus Reset password and Deactivate / Reactivate. Admins cannot
  deactivate themselves.

Create and edit routes need the module's write permission; a teacher typing `/students/new` is sent to the dashboard.
Failed loads show the error with "Try again" rather than retrying silently.

