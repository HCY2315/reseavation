-- Add migration script here

CREATE TYPE rsvp.reservation_status AS ENUM('unknow','pending','confirmed','blocked');

CREATE TYPE rsvp.reservation_update_type AS ENUM('unknow','create','update','delete');

CREATE TABLE rsvp.reservation (
    id uuid NOT NULL DEFAULT uuid_generate_v4(),
    user_id varchar(64) NOT NULL,
    status rsvp.reservation_status NOT NULL DEFAULT 'pending',
    resource_id varchar(64) NOT NULL,
    timespan tstzrange NOT NULL,
    start_time timestamptz NOT NULL,
    end_time timestamptz NOT NULL,
    note text,
    create_at timestamp with time zone NOT NULL DEFAULT now(),
    update_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT reservation_pkey PRIMARY KEY(id),
    CONSTRAINT reservation_conflict EXCLUDE USING gist (resource_id WITH =, timespan WITH &&)
);

CREATE INDEX reservation_resource_id_idx ON rsvp.reservation(resource_id);
CREATE INDEX reservation_user_id_idx ON rsvp.reservation(user_id);