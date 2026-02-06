--
-- PostgreSQL database dump
--

\restrict AntTFpgXp1AyNIgbHl1bsJ7y93ZK6RMshOByOz4t8fNSbEONS9QUo0Hy4iBkN2s

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
-- PostgreSQL database dump complete
--

\unrestrict AntTFpgXp1AyNIgbHl1bsJ7y93ZK6RMshOByOz4t8fNSbEONS9QUo0Hy4iBkN2s

