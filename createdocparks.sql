--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: contacts; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE TABLE docparks (
    id integer NOT NULL,
    "Overlays" character varying(255),
    "NaPALIS_ID" integer,
    "End_Date" character varying(255),
    "Vested" character varying(255),
    "Section" character varying(255),
    "Classified" character varying(255),
    "Legislatio" character varying(255),
    "Recorded_A" character varying(255),
    "Conservati" character varying(255),
    "Control_Ma" character varying(255),
    "Government" character varying(255),
    "Private_Ow" character varying(255),
    "Local_Purp" character varying(255),
    "Type" character varying(255),
    "Sart_Date" character varying(255),
    "Name" character varying(255),
    "WKT" geometry(MultiPolygon,4326)
);


ALTER TABLE docparks OWNER TO mbriggs;

--
-- Name: docparks_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE docparks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE docparks_id_seq OWNER TO mbriggs;

--
-- Name: docparks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE docparks_id_seq OWNED BY docparks.id;


--
-- Name: huts; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--
CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

