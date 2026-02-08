--
-- Name: tsv_markers; Type: VIEW; Schema: public; Owner: nn
--

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
    tsv.text
   FROM public.tsv
  where text in ( select text from marker_text );
select * from tsv_markers;


ALTER TABLE public.tsv_markers OWNER TO nn;

--
-- Name: tsv_all_ranges; Type: VIEW; Schema: public; Owner: nn
--

CREATE or replace VIEW public.tsv_all_ranges AS
 SELECT tsv,
    lead(tsv_markers.tsv) OVER (ORDER BY tsv_markers.page, tsv_markers.y1, tsv_markers.x1, tsv_markers.level) AS lead
   FROM public.tsv_markers
  ORDER BY tsv_markers.page, tsv_markers.y1, tsv_markers.x1, tsv_markers.level;
drop view tsv_all_ranges;

ALTER TABLE public.tsv_all_ranges OWNER TO nn;

--
-- Name: tsv_pairs; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_pairs AS
 SELECT tsv_markers.tsv AS tsv0,
    tsv_markers.text AS text0,
    lead(tsv_markers.tsv) OVER (ORDER BY tsv_markers.page, tsv_markers.y1, tsv_markers.x1, tsv_markers.level) AS tsv1,
    lead(tsv_markers.text) OVER (ORDER BY tsv_markers.page, tsv_markers.y1, tsv_markers.x1, tsv_markers.level) AS text1
   FROM public.tsv_markers
  ORDER BY tsv_markers.page, tsv_markers.y1, tsv_markers.x1, tsv_markers.level;

ALTER TABLE public.tsv_pairs OWNER TO nn;

--
-- Name: tsv_ranges; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_ranges AS
 SELECT rank() OVER (ORDER BY tsv_all_ranges.tsv) AS rid,
    tsv_all_ranges.tsv,
    tsv_all_ranges.lead
   FROM public.tsv_all_ranges
  WHERE (tsv_all_ranges.text = ANY (ARRAY['TRANSACTIONS'::text, 'INVESTMENTS'::text]));


ALTER TABLE public.tsv_ranges OWNER TO nn;

--
-- Name: tsv_section; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_section AS
 SELECT rank() OVER (ORDER BY tsv_pairs.tsv0) AS tsv0,
    tsv_pairs.text0,
    tsv_pairs.tsv1,
    tsv_pairs.text1
   FROM public.tsv_pairs
  WHERE (tsv_pairs.text0 = ANY (ARRAY['INVESTMENTS'::text, 'TRANSACTIONS'::text]));


ALTER TABLE public.tsv_section OWNER TO nn;
