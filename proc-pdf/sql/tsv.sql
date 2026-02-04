--
-- PostgreSQL database dump
--

\restrict j92tfZ6Li4aMe7sfBDKHg5MExjNpae8DoktlK6WrIgG8WBvWJbRWOFWfRggJWuh

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

--
-- Name: get_tsv_id(bigint, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: nn
--

CREATE FUNCTION public.get_tsv_id(page bigint, l integer, t integer, level integer) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    SELECT (
    (page - 2020000) * 10000000000) +
    (l * 1000000 + 
    (t * 10) + 
    (level)
  )
$$;


ALTER FUNCTION public.get_tsv_id(page bigint, l integer, t integer, level integer) OWNER TO nn;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: tsv_raw; Type: TABLE; Schema: public; Owner: nn
--

CREATE TABLE public.tsv_raw (
    level integer NOT NULL,
    page integer NOT NULL,
    block integer,
    par integer,
    line integer,
    word integer,
    l integer NOT NULL,
    t integer NOT NULL,
    w integer,
    h integer,
    conf double precision,
    text text
);


ALTER TABLE public.tsv_raw OWNER TO nn;

--
-- Name: tsv_id(public.tsv_raw); Type: FUNCTION; Schema: public; Owner: nn
--

CREATE FUNCTION public.tsv_id(r public.tsv_raw) RETURNS bigint
    LANGUAGE sql IMMUTABLE PARALLEL SAFE
    AS $$
    -- Use dot notation to access fields from the row argument 'r'
    SELECT (r.page::bigint - 2020000) * 10000000000 + r.t * 1000000 + r.l * 10 + r.level
$$;


ALTER FUNCTION public.tsv_id(r public.tsv_raw) OWNER TO nn;

--
-- Name: tsv; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv AS
 SELECT public.tsv_id(tsv_raw.*) AS tsv,
    tsv_raw.level,
    tsv_raw.page,
    tsv_raw.block,
    tsv_raw.par,
    tsv_raw.line,
    tsv_raw.word,
    tsv_raw.l,
    tsv_raw.t,
    tsv_raw.w,
    tsv_raw.h,
    tsv_raw.conf,
    tsv_raw.text
   FROM public.tsv_raw;


ALTER TABLE public.tsv OWNER TO nn;

--
-- Name: marker; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.marker AS
 SELECT tsv.tsv,
    tsv.text
   FROM public.tsv
  WHERE (tsv.text = ANY (ARRAY['TRANSACTIONS'::text, 'INVESTMENTS'::text, 'Page'::text, 'INSURED'::text]))
  ORDER BY tsv.tsv;


ALTER TABLE public.marker OWNER TO nn;

--
-- Name: page; Type: TABLE; Schema: public; Owner: nn
--

CREATE TABLE public.page (
    id integer,
    name text,
    year integer,
    quar integer,
    lpage integer
);


ALTER TABLE public.page OWNER TO nn;

--
-- Name: section_all; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.section_all AS
 SELECT marker.text AS text0,
    marker.tsv AS tsv0,
    lead(marker.tsv) OVER (ORDER BY marker.tsv) AS tsvn,
    lead(marker.text) OVER (ORDER BY marker.tsv) AS textn
   FROM public.marker;


ALTER TABLE public.section_all OWNER TO nn;

--
-- Name: section; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.section AS
 SELECT section_all.text0,
    section_all.tsv0,
    section_all.tsvn,
    section_all.textn
   FROM public.section_all
  WHERE (section_all.text0 = ANY (ARRAY['INVESTMENTS'::text, 'TRANSACTIONS'::text]));


ALTER TABLE public.section OWNER TO nn;

--
-- Name: tsv_s; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_s AS
 SELECT tsv_raw.ctid,
    (''::text || tsv_raw.level) AS levels,
    (''::text || tsv_raw.page) AS pages,
    (''::text || tsv_raw.l) AS ls,
    (''::text || tsv_raw.t) AS ts
   FROM public.tsv_raw;


ALTER TABLE public.tsv_s OWNER TO nn;

--
-- Name: tsv_m; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_m AS
 SELECT max(length(tsv_s.levels)) AS levelm,
    max(length(tsv_s.pages)) AS pagem,
    max(length(tsv_s.ts)) AS tm,
    max(length(tsv_s.ls)) AS lm
   FROM public.tsv_s;


ALTER TABLE public.tsv_m OWNER TO nn;

--
-- Name: tsv_id; Type: VIEW; Schema: public; Owner: nn
--

CREATE VIEW public.tsv_id AS
 SELECT tsv_s.ctid,
    concat(lpad(tsv_s.pages, tsv_m.pagem, '_'::text), lpad(tsv_s.ts, (tsv_m.tm + 1), '_'::text), lpad(tsv_s.ls, (tsv_m.lm + 1), '_'::text), lpad(tsv_s.levels, (tsv_m.levelm + 1), '_'::text)) AS concat
   FROM public.tsv_s,
    public.tsv_m;


ALTER TABLE public.tsv_id OWNER TO nn;

--
-- Name: tsv_raw tsv_pkey; Type: CONSTRAINT; Schema: public; Owner: nn
--

ALTER TABLE ONLY public.tsv_raw
    ADD CONSTRAINT tsv_pkey PRIMARY KEY (level, page, t, l);


--
-- Name: idx_tsv_raw_synthetic_id; Type: INDEX; Schema: public; Owner: nn
--

CREATE INDEX idx_tsv_raw_synthetic_id ON public.tsv_raw USING btree (public.tsv_id(tsv_raw.*));


--
-- Name: idx_tsv_synthetic_id; Type: INDEX; Schema: public; Owner: nn
--

CREATE INDEX idx_tsv_synthetic_id ON public.tsv_raw USING btree ((((((((((page)::bigint - 2020000) * 100000) * 100000) * 10) + ((l * 100000) * 10)) + (t * 10)) + level)));


--
-- PostgreSQL database dump complete
--

\unrestrict j92tfZ6Li4aMe7sfBDKHg5MExjNpae8DoktlK6WrIgG8WBvWJbRWOFWfRggJWuh

