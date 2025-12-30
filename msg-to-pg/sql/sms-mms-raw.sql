-- SMS: one row per <sms> node
create table sms_raw (
    id          bigserial primary key,
    file_name   text    not null,      -- backup filename
    idx_in_file integer not null,      -- position of this node in that file
    parsed      jsonb   not null,      -- JSON form of the Perl hash
    source_id   text    not null,      -- stable unique key
    unique (source_id)
);

create index sms_raw_file_idx on sms_raw (file_name, idx_in_file);

-- MMS: one row per <mms> node
create table mms_raw (
    id          bigserial primary key,
    file_name   text    not null,
    idx_in_file integer not null,
    parsed      jsonb   not null,
    source_id   text    not null,
    unique (source_id)
);

create index mms_raw_file_idx on mms_raw (file_name, idx_in_file);
