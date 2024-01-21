-- Add migration script here

CREATE OR REPLACE FUNCTION rsvp.query(uid text, rid text, during TSTZRANGE) RETURNS TABLE (LIKE rsvp.reservation) AS $$ 
BEGIN
    IF uid IS NULL AND rid IS NULL THEN
        RETURN QUERY SELECT * FROM rsvp.reservation WHERE timespan && during;
    ELSIF uid IS NULL THEN
        RETURN QUERY SELECT * FROM rsvp.reservation WHERE resource_id = rid AND during @> timespan;
    ELSIF rid IS NULL THEN 
        RETURN QUERY SELECT * FROM rsvp.reservation WHERE uid = uid AND during @> timespan;
    ELSE 
        RETURN QUERY SELECT * FROM rsvp.reservation WHERE resource_id = rid AND user_id = uid AND during @> timespan;
    END IF;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION rsvp.reservations_trigger() RETURNS TRIGGER AS 
$$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO rsvp.reservation_changes (reservation_id, op) VALUES 
        (NEW.id, 'create');
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status <> NEW.status THEN
            INSERT INTO rsvp.reservation_changes (reservation_id, op) VALUES 
            (NEW.id, 'update');
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO rsvp.reservation_changes (reservation_id, op) VALUES 
        (OLD.id, 'delete');
    END IF;
    NOTIFY reservation_update;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;