CREATE FUNCTION public.dane_date(sec integer) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT to_char(
        to_timestamp(sec),
        'YYYY-MM-DD HH24:MI:SS'
    );
$$;


ALTER FUNCTION public.dane_date(sec integer) OWNER TO nn;

--
-- Name: dane_date(bigint); Type: FUNCTION; Schema: public; Owner: nn
--

CREATE FUNCTION public.dane_date(ms bigint) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT to_char(
        to_timestamp(ms / 1000.0),
        'YYYY-MM-DD HH24:MI:SS'
    );
$$;


ALTER FUNCTION public.dane_date(ms bigint) OWNER TO nn;

--
-- Name: dane_date(timestamp without time zone); Type: FUNCTION; Schema: public; Owner: nn
--

CREATE FUNCTION public.dane_date(ts timestamp without time zone) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
    SELECT to_char(
        ts,
        'YYYY-MM-DD HH24:MI:SS'
    );
$$;


ALTER FUNCTION public.dane_date(ts timestamp without time zone) OWNER TO nn;
