CREATE VIEW public.smms_for_peers AS
 SELECT s.kind,
    s.raw_id,
    s.file_name,
    s.idx_in_file,
    s.source_id,
    s.date_ms,
    s.date_sent_ms,
    s.readable_date,
    s.msg_box,
    s.peer,
    s.parsed
   FROM (public.smms_with_peers s
     LEFT JOIN public.peers p ON ((s.peer = p.peer)));


ALTER TABLE public.smms_for_peers OWNER TO nn;
