CREATE VIEW public.tsv_markers AS
 SELECT tsv.tsv,
    tsv.level,
    tsv.page,
    tsv.block,
    tsv.par,
    tsv.line,
    tsv.word,
    tsv.y1,
    tsv.y2,
    tsv.x1,
    tsv.x2,
    tsv.conf,
    tsv.text,
    marker_text.prim
   FROM public.tsv,
    public.marker_text
  WHERE (tsv.text = marker_text.text);
