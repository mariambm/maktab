-- When classes meet, who teaches them, and which students are in them.
-- Assignment and enrolment periods are half-open: a row covers start_date up to, but not including, end_date.
-- An open row (end_date IS NULL) is the current one. Rows are closed, never deleted, so history is kept.

CREATE TABLE class_schedule (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    class_group_id uuid     NOT NULL REFERENCES class_group (id) ON DELETE CASCADE,
    weekday        smallint NOT NULL CHECK (weekday BETWEEN 1 AND 7), -- ISO: 1 = Monday
    start_time     time     NOT NULL,
    end_time       time     NOT NULL,
    CONSTRAINT ck_class_schedule_times CHECK (end_time > start_time),
    CONSTRAINT uq_class_schedule_slot UNIQUE (class_group_id, weekday, start_time)
);

CREATE TABLE class_teacher (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    class_group_id  uuid        NOT NULL REFERENCES class_group (id),
    teacher_user_id uuid        NOT NULL REFERENCES app_user (id),
    start_date      date        NOT NULL,
    end_date        date,
    created_at      timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_class_teacher_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX ix_class_teacher_teacher ON class_teacher (teacher_user_id, end_date);
CREATE INDEX ix_class_teacher_class ON class_teacher (class_group_id, end_date);
CREATE UNIQUE INDEX uq_class_teacher_open ON class_teacher (class_group_id, teacher_user_id) WHERE end_date IS NULL;

CREATE TABLE class_enrollment (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id     uuid        NOT NULL REFERENCES student (id),
    class_group_id uuid        NOT NULL REFERENCES class_group (id),
    start_date     date        NOT NULL,
    end_date       date,
    created_at     timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_class_enrollment_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

CREATE INDEX ix_class_enrollment_class ON class_enrollment (class_group_id, end_date);
CREATE INDEX ix_class_enrollment_student ON class_enrollment (student_id, start_date);
-- A student is in at most one class at a time.
CREATE UNIQUE INDEX uq_class_enrollment_open ON class_enrollment (student_id) WHERE end_date IS NULL;
