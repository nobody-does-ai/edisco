CREATE VIEW public.raw_smms AS
 SELECT 'sms'::text AS kind,
    s.id AS raw_id,
    s.file_name,
    s.idx_in_file,
    s.source_id,
    ((s.parsed ->> 'date'::text))::bigint AS date_ms,
    (NULLIF((s.parsed ->> 'date_sent'::text), ''::text))::bigint AS date_sent_ms,
    (s.parsed ->> 'readable_date'::text) AS readable_date,
    (s.parsed ->> 'address'::text) AS peer_address,
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
    NULL::text AS peer_address,
    m.parsed
   FROM public.mms_raw m;
