-- Lessons (one meeting of a class on a date), the curriculum topics they covered, and attendance per student.
-- Calculated values (attendance percentage, absence and lateness counts) are not stored.

CREATE TABLE lesson (
    id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    class_group_id    uuid        NOT NULL REFERENCES class_group (id),
    -- The weekly slot this lesson came from; kept as NULL when the schedule is later replaced.
    class_schedule_id uuid REFERENCES class_schedule (id) ON DELETE SET NULL,
    lesson_date       date        NOT NULL,
    start_time        time        NOT NULL,
    end_time          time        NOT NULL,
    -- Who opened the lesson (normally the teacher giving it).
    teacher_user_id   uuid        NOT NULL REFERENCES app_user (id),
    content_notes     varchar(2000),
    status            varchar(20) NOT NULL DEFAULT 'PLANNED'
        CHECK (status IN ('PLANNED', 'COMPLETED', 'CANCELLED')),
    created_at        timestamptz NOT NULL DEFAULT now(),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    version           bigint      NOT NULL DEFAULT 0,
    CONSTRAINT ck_lesson_times CHECK (end_time > start_time),
    CONSTRAINT uq_lesson_slot UNIQUE (class_group_id, lesson_date, start_time)
);

CREATE INDEX ix_lesson_date ON lesson (lesson_date);
CREATE INDEX ix_lesson_teacher_date ON lesson (teacher_user_id, lesson_date);

CREATE TABLE lesson_topic_covered (
    lesson_id       uuid NOT NULL REFERENCES lesson (id) ON DELETE CASCADE,
    lesson_topic_id uuid NOT NULL REFERENCES lesson_topic (id),
    PRIMARY KEY (lesson_id, lesson_topic_id)
);

CREATE INDEX ix_lesson_topic_covered_topic ON lesson_topic_covered (lesson_topic_id);

CREATE TABLE lesson_attendance (
    id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id      uuid        NOT NULL REFERENCES lesson (id),
    student_id     uuid        NOT NULL REFERENCES student (id),
    status         varchar(10) NOT NULL CHECK (status IN ('PRESENT', 'LATE', 'ABSENT')),
    minutes_late   smallint CHECK (minutes_late BETWEEN 1 AND 300),
    absence_reason varchar(20)
        CHECK (absence_reason IN ('SICK', 'FAMILY_REASON', 'HOLIDAY', 'UNKNOWN', 'OTHER')),
    note           varchar(500),
    recorded_by    uuid        NOT NULL REFERENCES app_user (id),
    created_at     timestamptz NOT NULL DEFAULT now(),
    updated_at     timestamptz NOT NULL DEFAULT now(),
    version        bigint      NOT NULL DEFAULT 0,
    CONSTRAINT uq_lesson_attendance UNIQUE (lesson_id, student_id),
    CONSTRAINT ck_lesson_attendance_late CHECK ((status = 'LATE') = (minutes_late IS NOT NULL)),
    CONSTRAINT ck_lesson_attendance_reason CHECK (status = 'ABSENT' OR absence_reason IS NULL)
);

CREATE INDEX ix_lesson_attendance_student ON lesson_attendance (student_id);
