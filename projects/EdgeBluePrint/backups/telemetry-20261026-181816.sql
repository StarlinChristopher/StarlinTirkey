--
-- PostgreSQL database dump
--

\restrict 3Vb5tOsuKezwDwQg0H4ZhorKYHcMN6ixAb38HJaxCsLyhjNVlMNFYzYHghqH6gx

-- Dumped from database version 15.19
-- Dumped by pg_dump version 15.19

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
-- Name: telemetry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.telemetry (
    id bigint NOT NULL,
    sensor_id character varying(128) NOT NULL,
    temperature double precision NOT NULL,
    received_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: telemetry_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.telemetry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: telemetry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.telemetry_id_seq OWNED BY public.telemetry.id;


--
-- Name: telemetry id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry ALTER COLUMN id SET DEFAULT nextval('public.telemetry_id_seq'::regclass);


--
-- Data for Name: telemetry; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.telemetry (id, sensor_id, temperature, received_at) FROM stdin;
1	smoke-test	21.5	2026-10-26 11:39:19.86571+00
2	smoke-test	21.5	2026-10-26 12:02:27.288293+00
3	smoke-test	21.5	2026-10-26 12:47:59.140155+00
\.


--
-- Name: telemetry_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.telemetry_id_seq', 3, true);


--
-- Name: telemetry telemetry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telemetry
    ADD CONSTRAINT telemetry_pkey PRIMARY KEY (id);


--
-- Name: telemetry_received_at_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX telemetry_received_at_idx ON public.telemetry USING btree (received_at);


--
-- PostgreSQL database dump complete
--

\unrestrict 3Vb5tOsuKezwDwQg0H4ZhorKYHcMN6ixAb38HJaxCsLyhjNVlMNFYzYHghqH6gx

