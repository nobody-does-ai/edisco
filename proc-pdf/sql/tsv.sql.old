--
-- PostgreSQL database dump
--


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
-- Name: doc; Type: TABLE; Schema: public; Owner: nn
--

CREATE TABLE public.doc (
    doc integer NOT NULL,
    file text NOT NULL,
    pages integer NOT NULL
);


ALTER TABLE public.doc OWNER TO nn;

--
-- Name: tsv; Type: TABLE; Schema: public; Owner: nn
--

CREATE TABLE public.tsv (
    tsv integer,
    doc integer,
    level integer,
    page_num integer,
    block_num integer,
    par_num integer,
    line_num integer,
    word_num integer,
    left_px integer,
    top_px integer,
    width_px integer,
    height_px integer,
    x_range int4range GENERATED ALWAYS AS (int4range(LEAST(left_px, (left_px + width_px)), GREATEST(left_px, (left_px + width_px)), '[)'::text)) STORED,
    y_range int4range GENERATED ALWAYS AS (int4range(LEAST(top_px, (top_px + height_px)), GREATEST(top_px, (top_px + height_px)), '[)'::text)) STORED,
    conf double precision,
    text text,
    reject integer
);


ALTER TABLE public.tsv OWNER TO nn;

--
-- Name: tsv_tmp; Type: TABLE; Schema: public; Owner: nn
--

CREATE UNLOGGED TABLE public.tsv_tmp (
    doc integer,
    level integer,
    page_num integer,
    block_num integer,
    par_num integer,
    line_num integer,
    word_num integer,
    left_px integer,
    top_px integer,
    width_px integer,
    height_px integer,
    conf double precision,
    text text,
    reject integer
);


ALTER TABLE public.tsv_tmp OWNER TO nn;

--
-- Name: doc doc_file_key; Type: CONSTRAINT; Schema: public; Owner: nn
--

ALTER TABLE ONLY public.doc
    ADD CONSTRAINT doc_file_key UNIQUE (file);


--
-- Name: doc doc_pkey; Type: CONSTRAINT; Schema: public; Owner: nn
--

ALTER TABLE ONLY public.doc
    ADD CONSTRAINT doc_pkey PRIMARY KEY (doc);


--
-- Name: tsv_x_range_gist; Type: INDEX; Schema: public; Owner: nn
--

CREATE INDEX tsv_x_range_gist ON public.tsv USING gist (x_range);


--
-- Name: tsv_y_range_gist; Type: INDEX; Schema: public; Owner: nn
--

CREATE INDEX tsv_y_range_gist ON public.tsv USING gist (y_range);


--
-- Name: tsv tsv_doc_fkey; Type: FK CONSTRAINT; Schema: public; Owner: nn
--

ALTER TABLE ONLY public.tsv
    ADD CONSTRAINT tsv_doc_fkey FOREIGN KEY (doc) REFERENCES public.doc(doc);


--
-- PostgreSQL database dump complete
--


