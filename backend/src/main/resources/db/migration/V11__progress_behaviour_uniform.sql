-- Student development recorded per lesson: a progress score per subject, behaviour observations and uniform.
-- Everything belongs to one lesson (and so one date); nothing here is a permanent label on a child.

-- The progress scale. Labels live here rather than in code so the mosque can change them without a release.
CREATE TABLE progress_scale_level (
    organisation_id uuid         NOT NULL REFERENCES organisation (id),
    score           numeric(2,1) NOT NULL CHECK (score > 0 AND score <= 9.9),
    label           varchar(50)  NOT NULL,
    PRIMARY KEY (organisation_id, score)
);

INSERT INTO progress_scale_level (organisation_id, score, label)
VALUES ('00000000-0000-0000-0000-000000000001', 2, 'Low'),
       ('00000000-0000-0000-0000-000000000001', 3, 'Medium'),
       ('00000000-0000-0000-0000-000000000001', 3.5, 'Almost Good'),
       ('00000000-0000-0000-0000-000000000001', 4, 'Good'),
       ('00000000-0000-0000-0000-000000000001', 4.5, 'Very Good'),
       ('00000000-0000-0000-0000-000000000001', 5, 'Excellent');

-- One score per student, lesson and subject.
CREATE TABLE student_progress (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id   uuid         NOT NULL REFERENCES lesson (id),
    student_id  uuid         NOT NULL REFERENCES student (id),
    subject     varchar(30)  NOT NULL
        CHECK (subject IN ('QURAN_RECITATION', 'ISLAMIC_STUDIES', 'NAMAZ_AND_DUAS', 'ARABIC', 'NAATS_AND_SPEECHES')),
    score       numeric(2,1) NOT NULL,
    note        varchar(500),
    recorded_by uuid         NOT NULL REFERENCES app_user (id),
    created_at  timestamptz  NOT NULL DEFAULT now(),
    updated_at  timestamptz  NOT NULL DEFAULT now(),
    version     bigint       NOT NULL DEFAULT 0,
    CONSTRAINT uq_student_progress UNIQUE (lesson_id, student_id, subject)
);

CREATE INDEX ix_student_progress_student ON student_progress (student_id);

-- What a teacher observed about one student in one lesson: any number of behaviours and an optional note.
CREATE TABLE behaviour_record (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id   uuid        NOT NULL REFERENCES lesson (id),
    student_id  uuid        NOT NULL REFERENCES student (id),
    note        varchar(500),
    recorded_by uuid        NOT NULL REFERENCES app_user (id),
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    version     bigint      NOT NULL DEFAULT 0,
    CONSTRAINT uq_behaviour_record UNIQUE (lesson_id, student_id)
);

CREATE INDEX ix_behaviour_record_student ON behaviour_record (student_id);

CREATE TABLE behaviour_record_item (
    behaviour_record_id uuid        NOT NULL REFERENCES behaviour_record (id) ON DELETE CASCADE,
    behaviour           varchar(40) NOT NULL CHECK (behaviour IN (
        'GOOD_QURAN_RECITATION', 'LEARNED_ISLAMIC_STUDIES', 'LEARNED_NAMAZ_AND_DUAS', 'LEARNED_NAAT_OR_SPEECH',
        'LISTENED_TO_TEACHER', 'BEEN_HELPFUL', 'ORGANISED', 'RESPECTFUL', 'GOOD_GROUP_WORK',
        'USING_TIME_EFFECTIVELY',
        'OFF_TASK', 'NOT_LISTENING', 'DISTRACTING', 'TALKING', 'DISORGANISED', 'LACK_OF_EFFORT', 'WASTING_TIME',
        'SHOUTING', 'WALKING_OR_RUNNING_AROUND')),
    PRIMARY KEY (behaviour_record_id, behaviour)
);

-- Uniform as seen in one lesson. A reason only accompanies uniform that is not (fully) in order.
CREATE TABLE uniform_record (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    lesson_id   uuid        NOT NULL REFERENCES lesson (id),
    student_id  uuid        NOT NULL REFERENCES student (id),
    status      varchar(20) NOT NULL CHECK (status IN ('IN_ORDER', 'PARTIALLY_IN_ORDER', 'NOT_IN_ORDER')),
    reason      varchar(40)
        CHECK (reason IN ('HIJAB_MISSING', 'SHIRT_NOT_ACCORDING_TO_UNIFORM', 'OTHER')),
    note        varchar(500),
    recorded_by uuid        NOT NULL REFERENCES app_user (id),
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    version     bigint      NOT NULL DEFAULT 0,
    CONSTRAINT uq_uniform_record UNIQUE (lesson_id, student_id),
    CONSTRAINT ck_uniform_record_reason CHECK (status <> 'IN_ORDER' OR reason IS NULL)
);

CREATE INDEX ix_uniform_record_student ON uniform_record (student_id);
