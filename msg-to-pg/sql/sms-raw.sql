CREATE TABLE public.sms_raw (
    id bigint NOT NULL,
    file_name text NOT NULL,
    idx_in_file integer NOT NULL,
    parsed jsonb NOT NULL,
    source_id text NOT NULL
);


ALTER TABLE public.sms_raw OWNER TO nn;
