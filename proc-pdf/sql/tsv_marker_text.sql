CREATE VIEW public.marker_text AS
 SELECT 'INVESTMENTS'::text AS text,
    1 AS prim
UNION
 SELECT 'TRANSACTIONS'::text AS text,
    1 AS prim
UNION
 SELECT 'INSURED'::text AS text,
    0 AS prim
UNION
 SELECT 'Page'::text AS text,
    0 AS prim;
