--
-- PostgreSQL database dump
--

\restrict ocje0J5vJLgWMt2XwMcG3Z1Bm08Nflz3aQLhfzBAdhBWaV5CBTLerrehVn0vvWE

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
    tsv integer NOT NULL,
    level integer NOT NULL,
    page text NOT NULL,
    block integer NOT NULL,
    par integer NOT NULL,
    line integer NOT NULL,
    word integer NOT NULL,
    x1 integer NOT NULL,
    y1 integer NOT NULL,
    dx integer NOT NULL,
    dy integer NOT NULL,
    conf double precision NOT NULL,
    text text
);


ALTER TABLE public.tsv OWNER TO nn;

--
-- Name: lines; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.lines AS
 SELECT tsv.tsv,
    tsv.page,
    tsv.y1,
    (tsv.y1 + tsv.dy) AS y2,
    tsv.text,
    rank() OVER (ORDER BY tsv.page, tsv.y1, tsv.x1) AS rank
   FROM public.tsv
  WHERE ((tsv.level = 5) AND (tsv.text = 'POLLOCK'::text));


ALTER TABLE public.lines OWNER TO nn;

--
-- Name: marker; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.marker AS
 SELECT tsv.tsv,
    tsv.page,
    tsv.y1,
    tsv.x1,
    tsv.text,
    rank() OVER (ORDER BY tsv.page, tsv.y1, tsv.x1) AS rank
   FROM public.tsv;


ALTER TABLE public.marker OWNER TO nn;

--
-- Name: tsv_order; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_order AS
 SELECT rank() OVER (ORDER BY tsv.page, tsv.y1, tsv.x1, tsv.level) AS tid,
    tsv.tsv,
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
  ORDER BY tsv.page, tsv.y1, tsv.x1, tsv.level;


ALTER TABLE public.tsv_order OWNER TO nn;

--
-- Name: tsv_markers; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_markers AS
 SELECT tsv_order.tid,
    tsv_order.tsv,
    tsv_order.level,
    tsv_order.page,
    tsv_order.block,
    tsv_order.par,
    tsv_order.line,
    tsv_order.word,
    tsv_order.x1,
    tsv_order.y1,
    tsv_order.dx,
    tsv_order.dy,
    tsv_order.conf,
    tsv_order.text
   FROM public.tsv_order
  WHERE (tsv_order.text = ANY (ARRAY['INVESTMENTS'::text, 'TRANSACTIONS'::text, 'Page'::text, 'INSURED'::text]));


ALTER TABLE public.tsv_markers OWNER TO nn;

--
-- Name: tsv_page; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_page AS
 SELECT rank() OVER (ORDER BY tsv.page, tsv.y1, tsv.x1) AS tid,
    tsv.tsv,
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
  ORDER BY tsv.page, tsv.y1, tsv.x1;


ALTER TABLE public.tsv_page OWNER TO nn;

--
-- Name: tsv_range; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_range AS
 SELECT foo.rid,
    foo.tid1,
    foo.text1,
    foo.tid2,
    foo.text2
   FROM ( SELECT rank() OVER (ORDER BY m1.tid) AS rid,
            m1.tid AS tid1,
            m1.text AS text1,
            lead(m1.tid) OVER (ORDER BY m1.tid) AS tid2,
            lead(m1.text) OVER (ORDER BY m1.tid) AS text2
           FROM public.tsv_markers m1) foo
  WHERE ((foo.text1 = 'INVESTMENTS'::text) OR (foo.text1 = 'TRANSACTIONS'::text));


ALTER TABLE public.tsv_range OWNER TO nn;

--
-- Name: tsv_range_w; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_range_w AS
 SELECT r.rid,
    t.tid,
    t.tsv,
    t.level,
    t.page,
    t.block,
    t.par,
    t.line,
    t.word,
    t.x1,
    t.y1,
    t.dx,
    t.dy,
    t.conf,
    t.text
   FROM public.tsv_range r,
    public.tsv_order t
  WHERE ((t.tid >= r.tid1) AND (t.tid <= r.tid2))
  ORDER BY t.tid;


ALTER TABLE public.tsv_range_w OWNER TO nn;

--
-- Name: tsv_temp; Type: TABLE; Schema: public; Owner: nn
--

CREATE UNLOGGED TABLE public.tsv_temp (
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


ALTER TABLE public.tsv_temp OWNER TO nn;

--
-- Name: tsv_tsv_seq; Type: SEQUENCE; Schema: public; Owner: nn
--

ALTER TABLE public.tsv ALTER COLUMN tsv ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.tsv_tsv_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: tsv tsv_page_t_l_level_key; Type: CONSTRAINT; Schema: public; Owner: nn
--

ALTER TABLE ONLY public.tsv
    ADD CONSTRAINT tsv_page_t_l_level_key UNIQUE (page, y1, x1, level);


--
-- Name: tsv tsv_pkey; Type: CONSTRAINT; Schema: public; Owner: nn
--

ALTER TABLE ONLY public.tsv
    ADD CONSTRAINT tsv_pkey PRIMARY KEY (tsv);


--
-- PostgreSQL database dump complete
--

\unrestrict ocje0J5vJLgWMt2XwMcG3Z1Bm08Nflz3aQLhfzBAdhBWaV5CBTLerrehVn0vvWE

