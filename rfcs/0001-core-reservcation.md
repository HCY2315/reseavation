# Service interface

```proto
enum ReservationStatus {
    UNKNOW = 0;
    RENDING = 1;
    CONFIGE = 2;
    BLOCKED = 3;
}

enum ReservationUpdateType {
    UNKNOW = 0;
    CREATE = 1;
    UPDATE = 2;
    DELETE = 3;
}

message Reservation {
    string id = 1;
    string user_id = 2;
    ReservationStatus status = 3;

    string resource_id = 4;
    google.protobuf.Timestamp  start_time = 5;
    google.protobuf.Timestamp  end_time = 6;

    string note = 7;
}

message  ReservateRequest {
    Reservation reservation = 1;
}

message  ReservateResponse {
    Reservation reservation = 1;
}

message  UpdateRequest {
    string note = 1;
}

message  UpdateResponse {
    Reservation reservation = 1;
}

message  ConfirmRequest {
    string id = 1;
}

message  ConfirmResponse {
    Reservation reservation = 1;
}

message  CancelRequest {
    string id = 1;
}

message  CancelResponse {
    Reservation id = 1;
}

message  GetRequest {
    string id = 1;
}

message  GetResponse {
    Reservation reservation = 1;
}

message  GetRequest {
    string id = 1;
}

message  GetResponse {
    Reservation reservation = 1;
}

message  QueryRequest {
    string resource_id = 1;
    string user_id = 2;

    ReservationStatus status = 3;
    google.protobuf.Timestamp  start_time = 5;
    google.protobuf.Timestamp  end_time = 6;
}

message  QueryResponse {
    Reservation reservation = 1;
    
}

message ListenRequest{
    repeat
}

message ListenResponse{
    int8 op = 1;
    Reservation reservation = 2;
}

service ReservationService {
    rpc reservce(ReservateRequest) returns (ReservateResponse);  
    rpc confirm(ConfirmRequest) returns (ConfirmResponse);  
    rpc update(UpdateRequest) returns (UpdateResponse); 
    rpc cancel(CancelRequest) returns (CancelResponse); 
    rpc get(GetRequest) returns (Reservation); 
    rpc query(QueryRequest) returns ( stream Reservation );  
}

```

```sql
CREATE SCHEMA rsvp;

CREATE TYPE rsvp.reservation_status AS ENUM('unknow','pending','confirmed','blocked');

CREATE TYPE rsvp.reservation_update_type AS ENUM('unknow','create','update','delete');

CREATE EXTENSION btree_gist;

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

CREATE OR REPLACE FUNCTION rsvp.query(uid text, rid text, during:TSTZRANGE) RETURNS TABLE rsvp.reservation AS 
$$ $$ LANGUAGE plpgsql;

CREATE TABLE rsvp.reservation_changes (
    id SERIAL NOT NULL,
    reservation_id uuid NOT NULL,
    op rsvp.reservation_update_type NOT NULL,
);

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

CREATE TRIGGER reservation_trigger
    AFTER INSERT OR  UPDATE OR DELETE ON rsvp.reservation
    FOR EACH ROW EXECUTE PROCEDURE rsvp.reservation_trigger();
```
