CREATE VIEW public.smms_with_peers AS
 SELECT 'sms'::text AS kind,
    s.id AS raw_id,
    s.file_name,
    s.idx_in_file,
    s.source_id,
    ((s.parsed ->> 'date'::text))::bigint AS date_ms,
    (NULLIF((s.parsed ->> 'date_sent'::text), ''::text))::bigint AS date_sent_ms,
    (s.parsed ->> 'readable_date'::text) AS readable_date,
    ((s.parsed ->> 'type'::text))::integer AS msg_box,
    (s.parsed ->> 'address'::text) AS peer,
    s.parsed
   FROM public.sms_raw s
UNION ALL
 SELECT 'mms'::text AS kind,
    m.id AS raw_id,
    m.file_name,
    m.idx_in_file,
    m.source_id,
    ((m.parsed ->> 'date'::text))::bigint AS date_ms,
    (NULLIF((m.parsed ->> 'date_sent'::text), ''::text))::bigint AS date_sent_ms,
    (m.parsed ->> 'readable_date'::text) AS readable_date,
    ((m.parsed ->> 'msg_box'::text))::integer AS msg_box,
    (addr_elem.value ->> 'address'::text) AS peer,
    m.parsed
   FROM (public.mms_raw m
     CROSS JOIN LATERAL jsonb_array_elements(COALESCE(((m.parsed -> 'addrs'::text) -> 'addr'::text), '[]'::jsonb)) addr_elem(value))
  WHERE (((addr_elem.value ->> 'type'::text))::integer = ANY (ARRAY[137, 151]));


ALTER TABLE public.smms_with_peers OWNER TO nn;
