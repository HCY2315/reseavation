-- Add migration script here

CREATE TABLE rsvp.reservation_changes (
    id SERIAL NOT NULL,
    reservation_id uuid NOT NULL,
    op rsvp.reservation_update_type NOT NULL,
);

CREATE TRIGGER reservation_trigger
    AFTER INSERT OR  UPDATE OR DELETE ON rsvp.reservation
    FOR EACH ROW EXECUTE PROCEDURE rsvp.reservation_trigger();