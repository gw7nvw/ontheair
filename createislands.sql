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

CREATE TABLE islands (
    id integer NOT NULL,
    "WKT" geometry(Point,4326)
    "name_id" integer,
    "name" character varying(255),
    "status" character varying(255),
    "feat_id" integer,
    "feat_type" character varying(255),
    "nzgb_ref" character varying(255),
    "land_district" character varying(255),
    "crd_projection" character varying(255),
    "crd_north" float,
    "crd_east" float,
    "crd_datum" character varying(255),
    "crd_latitude" float,
    "crd_longitude" float,
    "info_ref" character varying(255),
    "info_origin" character varying(255),
    "info_description" character varying(255),
    "info_note" character varying(255),
    "feat_note" character varying(255),
    "maori_name" character varying(255),
    "cpa_legislation" character varying(255),
    "conservancy" character varying(255),
    "doc_cons_unit_no" character varying(255),
    "doc_gaz_ref" character varying(255),
    "treaty_legislation" character varying(255),
    "geom_type" character varying(255),
    "accuracy" character varying(255),
    "gebco" character varying(255),
    "region" character varying(255),
    "scufn" character varying(255),
    "height" character varying(255),
    "ant_pn_ref" character varying(255),
    "ant_pgaz_ref" character varying(255),
    "scar_id" character varying(255),
    "scar_rec_by" character varying(255),
    "accuracy_rating" character varying(255),
    "desc_code" character varying(255),
    "rev_gaz_ref" character varying(255),
    "rev_treaty_legislation" character varying(255),
    "ref_point_X" float,
    "ref_point_Y" float
);


ALTER TABLE islands OWNER TO mbriggs;

--
-- Name: docparks_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE islands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE islands_id_seq OWNER TO mbriggs;

--
-- Name: docparks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE islands_id_seq OWNED BY islands.id;


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

