# Maktab

**Maktab — Mosque Education Management System.** A mobile-first app for mosques and Islamic education organisations
that teach children: students, parents and guardians, classes, lessons, attendance, curriculum, progress, behaviour,
uniform, payments and reports. It replaces an Excel-based administration.

| Part | Stack |
| --- | --- |
| `backend/` | Java 21, Spring Boot 4, Spring Security (JWT), Spring Data JPA, Flyway, PostgreSQL 17 |
| `frontend/` | Flutter (Material 3), Riverpod, Dio, go_router, secure token storage |
| `docs/` | [Architecture](docs/architecture.md), [database](docs/database.md), [API](docs/api.md), [UX](docs/ux.md) |

## Status

- Phase 1 (Foundation) is done: project setup, PostgreSQL with Flyway, login with JWT access tokens and rotating
  refresh tokens, roles and permissions, user administration API, audit log, the Maktab theme, and role-aware
  navigation in the app.
- Phase 2 (Administration) is done: students, parents and guardians, classes with curriculum levels, weekly
  schedules and teachers, and class enrolments with history. Teachers only see their own classes and students.

Modules from Phase 3 onwards show a placeholder screen. See the roadmap in
[docs/architecture.md](docs/architecture.md#roadmap).

## Run it locally

Requirements: Docker, and for the app the Flutter SDK (stable).

```bash
cp .env.example .env          # then edit the values; JWT_SECRET must be 32+ characters
docker compose up --build     # PostgreSQL on :5432, API on :8080
```

With the default `dev` profile the backend seeds fake accounts, all using `DEV_SEED_PASSWORD` from `.env`:

| Email | Role |
| --- | --- |
| `admin@maktab.local` | ADMIN |
| `administrator1@maktab.local`, `administrator2@maktab.local` | ADMINISTRATOR |
| `teacher1@maktab.local` … `teacher4@maktab.local` | TEACHER |

It also seeds a fake school once (when there are no students yet): 3 curriculum levels, 6 classes with schedules and
teachers, 30 students and 20 parents, 8 of whom have two or more children. `teacher1` teaches *Saturday Beginners A*
and *Sunday Qaida E*.

Swagger UI (dev profile only): http://localhost:8080/swagger-ui.html

Run the app:

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080   # Android emulator
flutter run --dart-define=API_BASE_URL=http://localhost:8080  # iOS simulator
```

For Flutter web during development, add its origin to `CORS_ALLOWED_ORIGINS` in `.env`
(for example `http://localhost:5050`) and run `flutter run -d chrome --web-port 5050`. Avoid port 5000 on macOS:
the AirPlay Receiver already uses it.

## Tests

```bash
cd backend && mvn verify      # unit + integration tests; needs Docker for Testcontainers
cd frontend && flutter test
```

Both suites run in GitHub Actions on every push and pull request (`.github/workflows/ci.yml`).

## Security notes

- Secrets come only from environment variables; `.env` is git-ignored. Never commit real values.
- Passwords are hashed with BCrypt; tokens and passwords are never logged or written to the audit log.
- Every endpoint other than login/refresh/logout requires a token and declares a permission; a test fails the build
  if a new endpoint is added without one.
- Error responses never contain stack traces; each carries a correlation id that matches the server log.
