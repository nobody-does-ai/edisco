CREATE VIEW public.overview AS
 SELECT raw_smms.file_name,
    min(raw_smms.date_ms) AS first_msg,
    max(raw_smms.date_ms) AS last_msg,
    count(*) AS messages
   FROM public.raw_smms
  GROUP BY raw_smms.file_name
  ORDER BY raw_smms.file_name;


ALTER TABLE public.overview OWNER TO nn;
