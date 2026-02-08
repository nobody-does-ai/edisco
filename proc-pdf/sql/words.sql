CREATE VIEW public.words AS
 SELECT *
   FROM public.tsv
  WHERE (tsv.level = 5);
