CREATE VIEW public.sms_parsed AS
 SELECT r.id,
    (r.parsed ->> 'readable_date'::text) AS date,
    (r.parsed ->> 'address'::text) AS address,
    (r.parsed ->> 'body'::text) AS body,
    ((r.parsed ->> 'type'::text))::integer AS msg_box,
    ((r.parsed ->> 'date'::text))::bigint AS date_ms,
    r.file_name,
    r.idx_in_file,
    r.source_id,
    (NULLIF((r.parsed ->> 'date_sent'::text), ''::text))::bigint AS date_sent_ms
   FROM public.sms_raw r;


ALTER TABLE public.sms_parsed OWNER TO nn;
