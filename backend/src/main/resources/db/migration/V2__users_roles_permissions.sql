CREATE TABLE app_user (
    id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organisation_id        uuid         NOT NULL REFERENCES organisation (id),
    email                  citext       NOT NULL,
    password_hash          varchar(100) NOT NULL,
    first_name             varchar(100) NOT NULL,
    last_name              varchar(100) NOT NULL,
    active                 boolean      NOT NULL DEFAULT true,
    must_change_password   boolean      NOT NULL DEFAULT false,
    last_login_at          timestamptz,
    created_at             timestamptz  NOT NULL DEFAULT now(),
    updated_at             timestamptz  NOT NULL DEFAULT now(),
    version                bigint       NOT NULL DEFAULT 0,
    CONSTRAINT uq_app_user_email UNIQUE (organisation_id, email)
);

CREATE TABLE user_role (
    user_id uuid        NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
    role    varchar(30) NOT NULL CHECK (role IN ('ADMIN', 'ADMINISTRATOR', 'TEACHER')),
    PRIMARY KEY (user_id, role)
);

-- Extra permissions granted to one user on top of their roles
-- (for example PAYMENT_READ for a specific teacher).
CREATE TABLE user_permission (
    user_id    uuid        NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
    permission varchar(50) NOT NULL,
    PRIMARY KEY (user_id, permission)
);
