--
-- PostgreSQL database dump
--

\restrict wGWfpeP1Lq1ZeVcL5ITRKu6aYySRxMrT2asNdkv8ZgxAe45VlDVMpgLkBXnVc6E

-- Dumped from database version 15.15 (Debian 15.15-0+deb12u1)
-- Dumped by pg_dump version 15.15 (Debian 15.15-0+deb12u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: tsv; Type: TABLE; Schema: public; Owner: nn
--

CREATE TABLE public.tsv (
    tsv bigint,
    level integer,
    page text,
    block integer,
    par integer,
    line integer,
    word integer,
    x1 integer,
    y1 integer,
    dx integer,
    dy integer,
    conf double precision,
    text text
);


ALTER TABLE public.tsv OWNER TO nn;

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
    tsv.x1,
    tsv.y1,
    tsv.dx,
    tsv.dy,
    tsv.conf,
    tsv.text
   FROM public.tsv
  WHERE (tsv.text = ANY (ARRAY['INVESTMENTS'::text, 'TRANSACTIONS'::text, 'Page'::text, 'INSURED'::text]));


ALTER TABLE public.tsv_markers OWNER TO nn;

--
-- Name: foo; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.foo AS
 SELECT tsv_markers.tsv,
    tsv_markers.level,
    tsv_markers.page,
    tsv_markers.block,
    tsv_markers.par,
    tsv_markers.line,
    tsv_markers.word,
    tsv_markers.x1,
    tsv_markers.y1,
    tsv_markers.dx,
    tsv_markers.dy,
    tsv_markers.conf,
    tsv_markers.text,
    lead(tsv_markers.tsv) OVER (ORDER BY tsv_markers.page, tsv_markers.y1, tsv_markers.x1, tsv_markers.level) AS lead
   FROM public.tsv_markers
  ORDER BY tsv_markers.page, tsv_markers.y1, tsv_markers.x1, tsv_markers.level;


ALTER TABLE public.foo OWNER TO nn;

--
-- Name: msg; Type: TABLE; Schema: public; Owner: nn
--

CREATE TABLE public.msg (
    msg integer NOT NULL,
    txt text
);


ALTER TABLE public.msg OWNER TO nn;

--
-- Name: tsv_all_ranges; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_all_ranges AS
 SELECT tsv_markers.tsv,
    tsv_markers.level,
    tsv_markers.page,
    tsv_markers.block,
    tsv_markers.par,
    tsv_markers.line,
    tsv_markers.word,
    tsv_markers.x1,
    tsv_markers.y1,
    tsv_markers.dx,
    tsv_markers.dy,
    tsv_markers.conf,
    tsv_markers.text,
    lead(tsv_markers.tsv) OVER (ORDER BY tsv_markers.page, tsv_markers.y1, tsv_markers.x1, tsv_markers.level) AS lead
   FROM public.tsv_markers
  ORDER BY tsv_markers.page, tsv_markers.y1, tsv_markers.x1, tsv_markers.level;


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
-- Name: tsv_rances; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_rances AS
 SELECT tsv_all_ranges.tsv,
    tsv_all_ranges.level,
    tsv_all_ranges.page,
    tsv_all_ranges.block,
    tsv_all_ranges.par,
    tsv_all_ranges.line,
    tsv_all_ranges.word,
    tsv_all_ranges.x1,
    tsv_all_ranges.y1,
    tsv_all_ranges.dx,
    tsv_all_ranges.dy,
    tsv_all_ranges.conf,
    tsv_all_ranges.text,
    tsv_all_ranges.lead
   FROM public.tsv_all_ranges
  WHERE (tsv_all_ranges.text = ANY (ARRAY['TRANSACTIONS'::text, 'INVESTMENTS'::text]));


ALTER TABLE public.tsv_rances OWNER TO nn;

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

--
-- Name: tsv_tmp; Type: TABLE; Schema: public; Owner: nn
--

CREATE UNLOGGED TABLE public.tsv_tmp (
    level integer,
    page text,
    block integer,
    par integer,
    line integer,
    word integer,
    x1 integer,
    y1 integer,
    dx integer,
    dy integer,
    conf double precision,
    text text
);


ALTER TABLE public.tsv_tmp OWNER TO nn;

--
-- Name: tsv_tmp_v; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_tmp_v AS
 SELECT rank() OVER (ORDER BY tsv_tmp.page, tsv_tmp.y1, tsv_tmp.x1, tsv_tmp.level) AS tsv,
    tsv_tmp.level,
    tsv_tmp.page,
    tsv_tmp.block,
    tsv_tmp.par,
    tsv_tmp.line,
    tsv_tmp.word,
    tsv_tmp.x1,
    tsv_tmp.y1,
    tsv_tmp.dx,
    tsv_tmp.dy,
    tsv_tmp.conf,
    tsv_tmp.text
   FROM public.tsv_tmp
  WHERE (tsv_tmp.level = 5)
  ORDER BY (rank() OVER (ORDER BY tsv_tmp.page, tsv_tmp.y1, tsv_tmp.x1, tsv_tmp.level));


ALTER TABLE public.tsv_tmp_v OWNER TO nn;

--
-- Name: tsv_tsv_seq; Type: SEQUENCE; Schema: public; Owner: nn
--

ALTER TABLE public.msg ALTER COLUMN msg ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tsv_tsv_seq
    START WITH 100000000
    INCREMENT BY 1
    MINVALUE 100000000
    MAXVALUE 999999999
    CACHE 1
);


--
-- Name: msg msg_pkey; Type: CONSTRAINT; Schema: public; Owner: nn
--

ALTER TABLE ONLY public.msg
    ADD CONSTRAINT msg_pkey PRIMARY KEY (msg);


--
-- PostgreSQL database dump complete
--

\unrestrict wGWfpeP1Lq1ZeVcL5ITRKu6aYySRxMrT2asNdkv8ZgxAe45VlDVMpgLkBXnVc6E

