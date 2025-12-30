CREATE VIEW public.sms_fat AS
 SELECT r.id,
    r.file_name,
    r.idx_in_file,
    r.source_id,
    ((r.parsed ->> 'date'::text))::bigint AS date_ms,
    (NULLIF((r.parsed ->> 'date_sent'::text), ''::text))::bigint AS date_sent_ms,
    (r.parsed ->> 'readable_date'::text) AS readable_date,
    ((r.parsed ->> 'type'::text))::integer AS msg_box,
    (r.parsed ->> 'address'::text) AS address,
    (r.parsed ->> 'body'::text) AS body,
    (r.parsed ->> 'locked'::text) AS locked,
    (r.parsed ->> 'protocol'::text) AS protocol,
    (r.parsed ->> 'service_center'::text) AS service_center,
    (r.parsed ->> 'status'::text) AS status,
    (r.parsed ->> 'sub_id'::text) AS sub_id,
    (r.parsed ->> 'read'::text) AS read_flag,
    (r.parsed ->> 'seen'::text) AS seen_flag
   FROM public.sms_raw r;


ALTER TABLE public.sms_fat OWNER TO nn;
