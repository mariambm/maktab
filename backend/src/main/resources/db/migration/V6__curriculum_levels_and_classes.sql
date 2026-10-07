-- Curriculum levels (for example Qaida, Quran) and the classes that follow them.

CREATE TABLE curriculum_level (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id uuid         NOT NULL REFERENCES organisation (id),
    name            varchar(100) NOT NULL,
    sort_order      smallint     NOT NULL DEFAULT 0,
    created_at      timestamptz  NOT NULL DEFAULT now(),
    updated_at      timestamptz  NOT NULL DEFAULT now(),
    version         bigint       NOT NULL DEFAULT 0,
    CONSTRAINT uq_curriculum_level_name UNIQUE (organisation_id, name)
);

CREATE TABLE class_group (
    id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id     uuid         NOT NULL REFERENCES organisation (id),
    curriculum_level_id uuid         NOT NULL REFERENCES curriculum_level (id),
    name                varchar(100) NOT NULL,
    room                varchar(50),
    active              boolean      NOT NULL DEFAULT true,
    created_at          timestamptz  NOT NULL DEFAULT now(),
    updated_at          timestamptz  NOT NULL DEFAULT now(),
    version             bigint       NOT NULL DEFAULT 0,
    CONSTRAINT uq_class_group_name UNIQUE (organisation_id, name)
);

CREATE INDEX ix_class_group_level ON class_group (curriculum_level_id);
