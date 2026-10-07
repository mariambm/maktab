-- Targets a student works towards in one four-week curriculum period. Targets of earlier periods stay as they were,
-- so a student's history of targets remains available.
CREATE TABLE student_target (
    id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id           uuid          NOT NULL REFERENCES student (id),
    curriculum_period_id uuid          NOT NULL REFERENCES curriculum_period (id),
    subject              varchar(30)
        CHECK (subject IN ('QURAN_RECITATION', 'ISLAMIC_STUDIES', 'NAMAZ_AND_DUAS', 'ARABIC', 'NAATS_AND_SPEECHES')),
    description          varchar(300)  NOT NULL,
    target_percentage    smallint CHECK (target_percentage BETWEEN 0 AND 100),
    current_percentage   smallint CHECK (current_percentage BETWEEN 0 AND 100),
    -- A step of the organisation's progress scale; checked by the API against progress_scale_level.
    progress_score       numeric(2,1),
    teacher_note         varchar(1000),
    created_by           uuid          NOT NULL REFERENCES app_user (id),
    updated_by           uuid          NOT NULL REFERENCES app_user (id),
    created_at           timestamptz   NOT NULL DEFAULT now(),
    updated_at           timestamptz   NOT NULL DEFAULT now(),
    version              bigint        NOT NULL DEFAULT 0
);

CREATE INDEX ix_student_target_student ON student_target (student_id);
CREATE INDEX ix_student_target_period ON student_target (curriculum_period_id);
