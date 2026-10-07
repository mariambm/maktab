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
The mosque's name sits under the logo there; if the server cannot be reached the screen simply shows the logo.

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

## Phase 3 screens

- **Lessons (Today)**: the day's lessons for the classes you can see, with the previous/next day arrows and a
  "Today" shortcut. Each card shows the time, class, room, how many students, and whether the lesson has been
  started and the register saved. Tapping a scheduled slot opens the lesson and goes straight to its register;
  because opening is idempotent, a double tap still lands on one lesson.
- **Lesson**: the register first, because that is why a teacher opens the screen. Everyone starts as Present, so
  only the exceptions need a tap: Late asks how many minutes, Absent offers the mosque's reasons (authorised, non authorised,
  sick, holiday, not reading) without picking one for the teacher, and both can carry a short note. "All present" resets the list, and the whole register is saved in one request. Below it, the topics of that
  curriculum week can be ticked off, with a note about what was taught and whether the lesson went ahead. Someone
  without `LESSON_RECORD` sees the same register as read-only text.
- **Curriculum**: the four-week periods per level, the one running now marked, and a period's page showing weeks 1
  to 4 with their topics, each with its subject from the teaching list (Quran Recitation, Islamic Studies, Namaz
  and Duas, Arabic, Naats and Speeches) and its learning objective; week 4 is marked as the review week. Administrators add or edit a
  period and its topics in one form; the end date is not asked for, since a period always runs four weeks.
- **Student Profile** gains an attendance card: the percentage, the lesson count, and present / late / absent, with
  a warning when the student is below the organisation's threshold.

## Phase 4 screens

- **Lesson** gains three sections under the register, each saved on its own:
  - **Progress**: choose the subject (it starts on the subject of this week's first topic, otherwise Quran
    Recitation) and tap a score per student on the mosque's scale (2, 3, 3.5, 4, 4.5, 5). The chosen score's label
    shows next to the name, tapping it again clears it, and absent students get no score.
  - **Behaviour**: one row per student who was there, "Nothing noted" until the teacher taps it. A sheet offers
    the good behaviours and the ones that need attention as chips, any number of each, plus an optional note; Done
    and Clear stay in view.
  - **Uniform**: In order, Partly in order or Not in order per student, with an optional reason when it is not in
    order. Nothing is assumed: "All in order" fills in only the students not noted yet.
  Without `PROGRESS_RECORD` or `OBSERVATION_RECORD` the sections are read-only text.
- **Student Profile** gains Progress, Behaviour and Uniform cards: the five most recent entries, each with its
  lesson date, and "Show all" for the rest.

Create and edit routes need the module's write permission; a teacher typing `/students/new` is sent to the dashboard.
Failed loads show the error with "Try again" rather than retrying silently.

