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
(account, change password, sign out, Users & Permissions for ADMIN), a read-only users list, and placeholders for
modules built in later phases.
