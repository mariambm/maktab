-- Curriculum: each level has numbered four-week periods; each period has weeks 1-4 with topics and learning
-- objectives. Week 4 is a review / assessment week by default.

CREATE TABLE curriculum_period (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    curriculum_level_id uuid         NOT NULL REFERENCES curriculum_level (id),
    number              smallint     NOT NULL CHECK (number > 0),
    name                varchar(100) NOT NULL,
    start_date          date         NOT NULL,
    end_date            date         NOT NULL,
    created_at          timestamptz  NOT NULL DEFAULT now(),
    updated_at          timestamptz  NOT NULL DEFAULT now(),
    version             bigint       NOT NULL DEFAULT 0,
    -- Four weeks: the end date is the last day of week 4 (inclusive).
    CONSTRAINT ck_curriculum_period_length CHECK (end_date = start_date + 27),
    CONSTRAINT uq_curriculum_period_number UNIQUE (curriculum_level_id, number)
);

CREATE INDEX ix_curriculum_period_level_dates ON curriculum_period (curriculum_level_id, start_date);

CREATE TABLE curriculum_week (
    id                   uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    curriculum_period_id uuid     NOT NULL REFERENCES curriculum_period (id) ON DELETE CASCADE,
    week_number          smallint NOT NULL CHECK (week_number BETWEEN 1 AND 4),
    is_review            boolean  NOT NULL DEFAULT false,
    CONSTRAINT uq_curriculum_week_number UNIQUE (curriculum_period_id, week_number)
);

CREATE TABLE lesson_topic (
    id                 uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    curriculum_week_id uuid         NOT NULL REFERENCES curriculum_week (id) ON DELETE CASCADE,
    title              varchar(200) NOT NULL,
    learning_objective varchar(500),
    sort_order         smallint     NOT NULL DEFAULT 0
);

CREATE INDEX ix_lesson_topic_week ON lesson_topic (curriculum_week_id, sort_order);
