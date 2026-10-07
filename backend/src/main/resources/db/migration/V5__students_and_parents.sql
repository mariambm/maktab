-- Students and their parents/guardians. Personal data is kept to what lessons and contact need (data minimisation):
-- no address, photo, school or medical information.

CREATE TABLE student (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id uuid          NOT NULL REFERENCES organisation (id),
    first_name      varchar(100)  NOT NULL,
    last_name       varchar(100)  NOT NULL,
    date_of_birth   date          NOT NULL,
    gender          varchar(10)   CHECK (gender IN ('FEMALE', 'MALE')),
    status          varchar(10)   NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    joined_on       date          NOT NULL,
    left_on         date,
    notes           varchar(1000),
    -- Lower-cased full name for search; backed by a trigram index.
    search_name     text GENERATED ALWAYS AS (lower(first_name || ' ' || last_name)) STORED,
    created_at      timestamptz   NOT NULL DEFAULT now(),
    updated_at      timestamptz   NOT NULL DEFAULT now(),
    version         bigint        NOT NULL DEFAULT 0,
    CONSTRAINT ck_student_left_after_joined CHECK (left_on IS NULL OR left_on >= joined_on),
    CONSTRAINT ck_student_inactive_has_left_on CHECK ((status = 'INACTIVE') = (left_on IS NOT NULL))
);

CREATE INDEX ix_student_organisation_name ON student (organisation_id, last_name, first_name);
CREATE INDEX ix_student_search_name ON student USING gin (search_name gin_trgm_ops);

CREATE TABLE parent_guardian (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id uuid         NOT NULL REFERENCES organisation (id),
    first_name      varchar(100) NOT NULL,
    last_name       varchar(100) NOT NULL,
    phone           varchar(30)  NOT NULL,
    email           citext,
    -- Reserved for the future parent portal; always NULL for now.
    user_id         uuid         REFERENCES app_user (id),
    search_name     text GENERATED ALWAYS AS (lower(first_name || ' ' || last_name)) STORED,
    created_at      timestamptz  NOT NULL DEFAULT now(),
    updated_at      timestamptz  NOT NULL DEFAULT now(),
    version         bigint       NOT NULL DEFAULT 0
);

CREATE INDEX ix_parent_guardian_organisation_name ON parent_guardian (organisation_id, last_name, first_name);
CREATE INDEX ix_parent_guardian_search_name ON parent_guardian USING gin (search_name gin_trgm_ops);

-- Many-to-many: a parent can have several children and a child several parents/guardians.
CREATE TABLE student_parent (
    student_id         uuid        NOT NULL REFERENCES student (id) ON DELETE CASCADE,
    parent_guardian_id uuid        NOT NULL REFERENCES parent_guardian (id) ON DELETE CASCADE,
    relationship       varchar(10) NOT NULL CHECK (relationship IN ('MOTHER', 'FATHER', 'GUARDIAN', 'OTHER')),
    is_primary_contact boolean     NOT NULL DEFAULT false,
    PRIMARY KEY (student_id, parent_guardian_id)
);

CREATE INDEX ix_student_parent_parent ON student_parent (parent_guardian_id);
-- At most one primary contact per student.
CREATE UNIQUE INDEX uq_student_parent_primary ON student_parent (student_id) WHERE is_primary_contact;
