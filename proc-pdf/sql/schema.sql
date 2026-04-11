--
-- PostgreSQL database dump
--

\restrict 3uYVyj8SoG6cd0yFgGFjYMGAiB0KUvIzz97R18AkHB0jWPuoLqiEfSMnm7Df19V

-- Dumped from database version 15.15 (Debian 15.15-0+deb12u1)
-- Dumped by pg_dump version 15.15 (Debian 15.15-0+deb12u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: cat_data(); Type: FUNCTION; Schema: public; Owner: claude
--

CREATE FUNCTION public.cat_data() RETURNS TABLE(cat text, descr text)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT 'International Fixed Income'::text, 'Non-US bonds and fixed income instruments'::text
  UNION ALL SELECT 'Domestic Fixed Income',  'US bonds and fixed income instruments'
  UNION ALL SELECT 'Domestic Equity',         'US stocks and equity funds'
  UNION ALL SELECT 'Cash & Equivalents',      'Money market and cash-like instruments'
  UNION ALL SELECT 'Alternative',             'Hedge funds, commodities, and other alternatives'
$$;


ALTER FUNCTION public.cat_data() OWNER TO claude;

--
-- Name: kind_data(); Type: FUNCTION; Schema: public; Owner: claude
--

CREATE FUNCTION public.kind_data() RETURNS TABLE(kind text, descr text)
    LANGUAGE sql IMMUTABLE
    AS $$
  SELECT 'income_dividend'::text,      'Cash dividend payment'::text
  UNION ALL SELECT 'income_capgain_long',   'Long-term capital gain distribution'
  UNION ALL SELECT 'income_capgain_short',  'Short-term capital gain distribution'
  UNION ALL SELECT 'income_interest',       'Interest or daily rate income'
  UNION ALL SELECT 'fee',                   'Advisory or platform fee'
  UNION ALL SELECT 'transfer_out',          'Cash disbursement or withdrawal'
  UNION ALL SELECT 'transfer_in',           'Cash deposit or contribution'
  UNION ALL SELECT 'trade_buy',             'Purchase of units or shares'
  UNION ALL SELECT 'trade_sell',            'Sale of units or shares'
  UNION ALL SELECT 'other',                 'Uncategorized transaction'
$$;


ALTER FUNCTION public.kind_data() OWNER TO claude;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: acct; Type: TABLE; Schema: public; Owner: claude
--

CREATE TABLE public.acct (
    acct text,
    name text
);


ALTER TABLE public.acct OWNER TO claude;

--
-- Name: cat; Type: VIEW; Schema: public; Owner: claude
--

CREATE VIEW public.cat AS
 SELECT cat_data.cat,
    cat_data.descr
   FROM public.cat_data() cat_data(cat, descr);


ALTER TABLE public.cat OWNER TO claude;

--
-- Name: inv; Type: TABLE; Schema: public; Owner: claude
--

CREATE TABLE public.inv (
    qtr text,
    acct integer,
    cat text,
    sym text,
    nshares double precision,
    sharep double precision,
    value double precision,
    basis double precision,
    unreal double precision
);


ALTER TABLE public.inv OWNER TO claude;

--
-- Name: kind; Type: VIEW; Schema: public; Owner: claude
--

CREATE VIEW public.kind AS
 SELECT kind_data.kind,
    kind_data.descr
   FROM public.kind_data() kind_data(kind, descr);


ALTER TABLE public.kind OWNER TO claude;

--
-- Name: sec; Type: TABLE; Schema: public; Owner: claude
--

CREATE TABLE public.sec (
    sym text NOT NULL,
    name text
);


ALTER TABLE public.sec OWNER TO claude;

--
-- Name: xact; Type: TABLE; Schema: public; Owner: claude
--

CREATE TABLE public.xact (
    qtr text,
    acct integer,
    date timestamp without time zone,
    kind text,
    cparty integer,
    sym text,
    units double precision,
    uprice double precision,
    rate double precision,
    total double precision,
    descr text
);


ALTER TABLE public.xact OWNER TO claude;

--
-- Name: sec sec_pkey; Type: CONSTRAINT; Schema: public; Owner: claude
--

ALTER TABLE ONLY public.sec
    ADD CONSTRAINT sec_pkey PRIMARY KEY (sym);


--
-- PostgreSQL database dump complete
--

\unrestrict 3uYVyj8SoG6cd0yFgGFjYMGAiB0KUvIzz97R18AkHB0jWPuoLqiEfSMnm7Df19V

