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


--
-- Name: postgres_fdw; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;


--
-- Name: EXTENSION postgres_fdw; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgres_fdw IS 'foreign-data wrapper for remote PostgreSQL servers';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: admin_settings; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE admin_settings (
    id integer NOT NULL,
    qrpnz_email character varying(255),
    admin_email character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    last_sota_activation_update_at timestamp without time zone,
    last_sota_update_at timestamp without time zone,
    last_pota_update_at timestamp without time zone,
    last_wwff_update_at timestamp without time zone,
    last_spot_read timestamp without time zone,
    sota_epoch character varying(255)
);


ALTER TABLE admin_settings OWNER TO route_guides_production;

--
-- Name: admin_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE admin_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE admin_settings_id_seq OWNER TO route_guides_production;

--
-- Name: admin_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE admin_settings_id_seq OWNED BY admin_settings.id;


--
-- Name: ak_maps; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE ak_maps (
    id integer NOT NULL,
    name character varying(255),
    code character varying(255),
    "WKT" geometry(MultiPolygon,4326),
    location geometry(Point,4326)
);


ALTER TABLE ak_maps OWNER TO route_guides_production;

--
-- Name: ak_maps_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE ak_maps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE ak_maps_id_seq OWNER TO route_guides_production;

--
-- Name: ak_maps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE ak_maps_id_seq OWNED BY ak_maps.id;


--
-- Name: asset_links; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE asset_links (
    id integer NOT NULL,
    contained_code character varying(255),
    containing_code character varying(255)
);


ALTER TABLE asset_links OWNER TO route_guides_production;

--
-- Name: asset_links_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE asset_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE asset_links_id_seq OWNER TO route_guides_production;

--
-- Name: asset_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE asset_links_id_seq OWNED BY asset_links.id;


--
-- Name: asset_photo_links; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE asset_photo_links (
    id integer NOT NULL,
    asset_code character varying(255),
    link_url character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    photo_id integer
);


ALTER TABLE asset_photo_links OWNER TO route_guides_production;

--
-- Name: asset_photo_links_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE asset_photo_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE asset_photo_links_id_seq OWNER TO route_guides_production;

--
-- Name: asset_photo_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE asset_photo_links_id_seq OWNED BY asset_photo_links.id;


--
-- Name: asset_types; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE asset_types (
    id integer NOT NULL,
    name character varying(255),
    table_name character varying(255),
    has_location boolean,
    has_boundary boolean,
    index_name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    display_name character varying(255),
    fields character varying(255),
    pnp_class character varying(255),
    keep_score boolean,
    min_qso integer,
    has_elevation boolean,
    ele_buffer integer,
    dist_buffer integer,
    is_zlota boolean,
    use_volcanic_field boolean
);


ALTER TABLE asset_types OWNER TO route_guides_production;

--
-- Name: asset_types_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE asset_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE asset_types_id_seq OWNER TO route_guides_production;

--
-- Name: asset_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE asset_types_id_seq OWNED BY asset_types.id;


--
-- Name: asset_web_links; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE asset_web_links (
    id integer NOT NULL,
    asset_code character varying(255),
    url character varying(255),
    link_class character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE asset_web_links OWNER TO route_guides_production;

--
-- Name: asset_web_links_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE asset_web_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE asset_web_links_id_seq OWNER TO route_guides_production;

--
-- Name: asset_web_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE asset_web_links_id_seq OWNED BY asset_web_links.id;


--
-- Name: assets; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE assets (
    id integer NOT NULL,
    asset_type character varying(255),
    code character varying(255),
    url character varying(255),
    name character varying(255),
    is_active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    boundary geometry(MultiPolygon,4326),
    location geometry(Point,4326),
    safecode character varying(255),
    category character varying(255),
    minor boolean,
    description text,
    altitude integer,
    "createdBy_id" integer,
    ref_id integer,
    land_district character varying(255),
    master_code character varying(255),
    region character varying(255),
    old_code character varying(255),
    area double precision,
    points integer,
    boundary_quite_simplified geometry(MultiPolygon,4326),
    boundary_simplified geometry(MultiPolygon,4326),
    boundary_very_simplified geometry(MultiPolygon,4326),
    district character varying(255),
    nearest_road_id integer,
    road_distance integer,
    valid_from timestamp without time zone,
    valid_to timestamp without time zone,
    is_nzart boolean,
    access_road_ids character varying(255)[] DEFAULT '{}'::character varying[],
    access_legal_road_ids character varying(255)[] DEFAULT '{}'::character varying[],
    access_park_ids character varying(255)[] DEFAULT '{}'::character varying[],
    access_track_ids character varying(255)[] DEFAULT '{}'::character varying[],
    public_access boolean,
    az_radius double precision,
    field_code character varying(255)
);


ALTER TABLE assets OWNER TO route_guides_production;

--
-- Name: assets_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE assets_id_seq OWNER TO route_guides_production;

--
-- Name: assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE assets_id_seq OWNED BY assets.id;


--
-- Name: award_thresholds; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE award_thresholds (
    id integer NOT NULL,
    threshold integer,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE award_thresholds OWNER TO route_guides_production;

--
-- Name: award_thresholds_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE award_thresholds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE award_thresholds_id_seq OWNER TO route_guides_production;

--
-- Name: award_thresholds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE award_thresholds_id_seq OWNED BY award_thresholds.id;


--
-- Name: award_user_links; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE award_user_links (
    id integer NOT NULL,
    user_id integer,
    award_id integer,
    notification_sent boolean,
    acknowledged boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    threshold integer,
    award_type character varying(255),
    activity_type character varying(255),
    linked_id integer,
    award_class character varying(255),
    expired_at timestamp without time zone,
    expired boolean
);


ALTER TABLE award_user_links OWNER TO route_guides_production;

--
-- Name: award_user_links_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE award_user_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE award_user_links_id_seq OWNER TO route_guides_production;

--
-- Name: award_user_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE award_user_links_id_seq OWNED BY award_user_links.id;


--
-- Name: awards; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE awards (
    id integer NOT NULL,
    name character varying(255),
    description text,
    email_text text,
    user_qrp boolean,
    contact_qrp boolean,
    is_active boolean,
    "createdBy_id" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    allow_repeat_visits boolean,
    count_based boolean,
    activated boolean,
    chased boolean,
    programme character varying(255),
    all_district boolean,
    all_region boolean,
    all_programme boolean,
    p2p boolean
);


ALTER TABLE awards OWNER TO route_guides_production;

--
-- Name: awards_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE awards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE awards_id_seq OWNER TO route_guides_production;

--
-- Name: awards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE awards_id_seq OWNED BY awards.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE comments (
    id integer NOT NULL,
    comment text,
    code character varying(255),
    updated_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE comments OWNER TO route_guides_production;

--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE comments_id_seq OWNER TO route_guides_production;

--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE comments_id_seq OWNED BY comments.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE TABLE contacts (
    id integer NOT NULL,
    callsign1 character varying(255),
    user1_id integer,
    power1 integer,
    signal1 character varying(255),
    transceiver1 character varying(255),
    antenna1 character varying(255),
    comments1 character varying(255),
    first_contact1 boolean DEFAULT true,
    loc_desc1 character varying(255),
    x1 double precision,
    y1 double precision,
    altitude1 integer,
    callsign2 character varying(255),
    user2_id integer,
    power2 integer,
    signal2 character varying(255),
    transceiver2 character varying(255),
    antenna2 character varying(255),
    comments2 character varying(255),
    first_contact2 boolean DEFAULT true,
    loc_desc2 character varying(255),
    x2 double precision,
    y2 double precision,
    altitude2 integer,
    date timestamp without time zone,
    "time" timestamp without time zone,
    timezone character varying(255),
    frequency double precision,
    mode character varying(255),
    is_active boolean DEFAULT true,
    "createdBy_id" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location1 geometry(Point,4326),
    location2 geometry(Point,4326),
    is_qrp1 boolean,
    is_portable1 boolean,
    is_qrp2 boolean,
    is_portable2 boolean,
    submitted_to_pota boolean,
    submitted_to_wwff boolean,
    submitted_to_sota boolean,
    log_id integer,
    asset1_codes character varying(255)[] DEFAULT '{}'::character varying[],
    asset2_codes character varying(255)[] DEFAULT '{}'::character varying[],
    name1 character varying(255),
    name2 character varying(255),
    asset1_classes character varying(255)[] DEFAULT '{}'::character varying[],
    asset2_classes character varying(255)[] DEFAULT '{}'::character varying[],
    submitted_to_hema boolean,
    band character varying(255),
    loc_source2 character varying(255)
);


ALTER TABLE contacts OWNER TO mbriggs;

--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE contacts_id_seq OWNER TO mbriggs;

--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE contacts_id_seq OWNED BY contacts.id;


--
-- Name: continents; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE continents (
    id integer NOT NULL,
    name character varying(255),
    code character varying(255)
);


ALTER TABLE continents OWNER TO route_guides_production;

--
-- Name: continents_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE continents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE continents_id_seq OWNER TO route_guides_production;

--
-- Name: continents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE continents_id_seq OWNED BY continents.id;


SET default_with_oids = true;

--
-- Name: crownparks; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE TABLE crownparks (
    "WKT" geometry(MultiPolygon,4326),
    id integer NOT NULL,
    napalis_id integer,
    start_date character varying(255),
    name character varying(255),
    recorded_area character varying(255),
    overlays character varying(255),
    reserve_type character varying(255),
    legislation character varying(255),
    section character varying(255),
    reserve_purpose character varying(255),
    ctrl_mg_vst character varying(255),
    is_active boolean,
    master_id integer
);


ALTER TABLE crownparks OWNER TO mbriggs;

SET default_with_oids = false;

--
-- Name: districts; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE districts (
    id integer NOT NULL,
    district_code character varying(255),
    region_code character varying(255),
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    boundary geometry(MultiPolygon,4326),
    boundary_quite_simplified geometry(MultiPolygon,4326),
    boundary_simplified geometry(MultiPolygon,4326),
    boundary_very_simplified geometry(MultiPolygon,4326)
);


ALTER TABLE districts OWNER TO route_guides_production;

--
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE districts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE districts_id_seq OWNER TO route_guides_production;

--
-- Name: districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE districts_id_seq OWNED BY districts.id;


--
-- Name: doc_tracks; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE doc_tracks (
    id integer NOT NULL,
    name character varying(255),
    object_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    linestring geometry(MultiLineString,4326)
);


ALTER TABLE doc_tracks OWNER TO route_guides_production;

--
-- Name: doc_tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE doc_tracks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE doc_tracks_id_seq OWNER TO route_guides_production;

--
-- Name: doc_tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE doc_tracks_id_seq OWNED BY doc_tracks.id;


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

ALTER SEQUENCE docparks_id_seq OWNED BY crownparks.id;


--
-- Name: dxcc_prefixes; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE dxcc_prefixes (
    id integer NOT NULL,
    name character varying(255),
    prefix character varying(255),
    itu_zone character varying(255),
    cq_zone character varying(255),
    continent_code character varying(255)
);


ALTER TABLE dxcc_prefixes OWNER TO route_guides_production;

--
-- Name: dxcc_prefixes_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE dxcc_prefixes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE dxcc_prefixes_id_seq OWNER TO route_guides_production;

--
-- Name: dxcc_prefixes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE dxcc_prefixes_id_seq OWNED BY dxcc_prefixes.id;


--
-- Name: external_activations; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE external_activations (
    id integer NOT NULL,
    callsign character varying(255),
    summit_code character varying(255),
    summit_sota_id integer,
    date date,
    qso_count integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_id integer,
    external_activation_id integer,
    asset_type character varying(255)
);


ALTER TABLE external_activations OWNER TO route_guides_production;

--
-- Name: external_activations_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE external_activations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE external_activations_id_seq OWNER TO route_guides_production;

--
-- Name: external_activations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE external_activations_id_seq OWNED BY external_activations.id;


--
-- Name: external_chases; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE external_chases (
    id integer NOT NULL,
    callsign character varying(255),
    summit_code character varying(255),
    summit_sota_id integer,
    user_id integer,
    external_activation_id integer,
    band character varying(255),
    mode character varying(255),
    date date,
    "time" time without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    asset_type character varying(255)
);


ALTER TABLE external_chases OWNER TO route_guides_production;

--
-- Name: external_chases_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE external_chases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE external_chases_id_seq OWNER TO route_guides_production;

--
-- Name: external_chases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE external_chases_id_seq OWNED BY external_chases.id;


--
-- Name: external_spots; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE external_spots (
    id integer NOT NULL,
    "time" timestamp without time zone,
    callsign character varying(255),
    "activatorCallsign" character varying(255),
    code character varying(255),
    name character varying(255),
    frequency character varying(255),
    mode character varying(255),
    comments character varying(255),
    spot_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    epoch character varying(255),
    is_test boolean,
    points character varying(255),
    "altM" character varying(255)
);


ALTER TABLE external_spots OWNER TO route_guides_production;

--
-- Name: external_spots_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE external_spots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE external_spots_id_seq OWNER TO route_guides_production;

--
-- Name: external_spots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE external_spots_id_seq OWNED BY external_spots.id;


--
-- Name: geological_eons; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE geological_eons (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE geological_eons OWNER TO route_guides_production;

--
-- Name: geological_eons_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE geological_eons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE geological_eons_id_seq OWNER TO route_guides_production;

--
-- Name: geological_eons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE geological_eons_id_seq OWNED BY geological_eons.id;


--
-- Name: geological_epoches; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE geological_epoches (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE geological_epoches OWNER TO route_guides_production;

--
-- Name: geological_epoches_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE geological_epoches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE geological_epoches_id_seq OWNER TO route_guides_production;

--
-- Name: geological_epoches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE geological_epoches_id_seq OWNED BY geological_epoches.id;


--
-- Name: geological_eras; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE geological_eras (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE geological_eras OWNER TO route_guides_production;

--
-- Name: geological_eras_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE geological_eras_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE geological_eras_id_seq OWNER TO route_guides_production;

--
-- Name: geological_eras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE geological_eras_id_seq OWNED BY geological_eras.id;


--
-- Name: geological_periods; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE geological_periods (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE geological_periods OWNER TO route_guides_production;

--
-- Name: geological_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE geological_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE geological_periods_id_seq OWNER TO route_guides_production;

--
-- Name: geological_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE geological_periods_id_seq OWNED BY geological_periods.id;


--
-- Name: humps; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE humps (
    id integer NOT NULL,
    dxcc character varying(255),
    region character varying(255),
    code character varying(255),
    name character varying(255),
    elevation character varying(255),
    prominence character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location geometry(Point,4326)
);


ALTER TABLE humps OWNER TO route_guides_production;

--
-- Name: humps_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE humps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE humps_id_seq OWNER TO route_guides_production;

--
-- Name: humps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE humps_id_seq OWNED BY humps.id;


--
-- Name: huts; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE TABLE huts (
    id integer NOT NULL,
    name character varying(255),
    hutbagger_link character varying(255),
    doc_link character varying(255),
    tramper_link character varying(255),
    routeguides_link character varying(255),
    general_link character varying(255),
    description text,
    x double precision,
    y double precision,
    altitude integer,
    is_active boolean DEFAULT true,
    is_doc boolean DEFAULT true,
    "createdBy_id" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location geometry(Point,4326),
    code character varying(255),
    region character varying(255),
    dist_code character varying(255)
);


ALTER TABLE huts OWNER TO mbriggs;

--
-- Name: huts_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE huts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE huts_id_seq OWNER TO mbriggs;

--
-- Name: huts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE huts_id_seq OWNED BY huts.id;


--
-- Name: images; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE images (
    id integer NOT NULL,
    title character varying(255),
    description text,
    filename character varying(255),
    image_file_name character varying(255),
    image_content_type character varying(255),
    image_file_size integer,
    image_updated_at timestamp without time zone,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    post_id integer
);


ALTER TABLE images OWNER TO route_guides_production;

--
-- Name: images_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE images_id_seq OWNER TO route_guides_production;

--
-- Name: images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE images_id_seq OWNED BY images.id;


--
-- Name: island_polygons; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE island_polygons (
    id integer NOT NULL,
    name_id integer,
    name character varying(255),
    status character varying(255),
    feat_id integer,
    feat_type character varying(255),
    nzgb_ref character varying(255),
    land_district character varying(255),
    crd_projection character varying(255),
    crd_north double precision,
    crd_east double precision,
    crd_datum character varying(255),
    crd_latitude double precision,
    crd_longitude double precision,
    info_ref text,
    info_origin text,
    info_description text,
    info_note text,
    feat_note text,
    maori_name character varying(255),
    cpa_legislation text,
    conservancy character varying(255),
    doc_cons_unit_no character varying(255),
    doc_gaz_ref character varying(255),
    treaty_legislation character varying(255),
    geom_type character varying(255),
    accuracy character varying(255),
    gebco character varying(255),
    region character varying(255),
    scufn character varying(255),
    height character varying(255),
    ant_pn_ref character varying(255),
    ant_pgaz_ref character varying(255),
    scar_id character varying(255),
    scar_rec_by character varying(255),
    accuracy_rating character varying(255),
    desc_code character varying(255),
    rev_gaz_ref character varying(255),
    rev_treaty_legislation character varying(255),
    "createdBy_id" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "WKT" geometry(MultiPolygon,4326)
);


ALTER TABLE island_polygons OWNER TO route_guides_production;

--
-- Name: island_polygons_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE island_polygons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE island_polygons_id_seq OWNER TO route_guides_production;

--
-- Name: island_polygons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE island_polygons_id_seq OWNED BY island_polygons.id;


--
-- Name: islands; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE islands (
    id integer NOT NULL,
    name_id integer,
    name character varying(255),
    status character varying(255),
    feat_id integer,
    feat_type character varying(255),
    nzgb_ref character varying(255),
    land_district character varying(255),
    crd_projection character varying(255),
    crd_north double precision,
    crd_east double precision,
    crd_datum character varying(255),
    crd_latitude double precision,
    crd_longitude double precision,
    info_ref text,
    info_origin text,
    info_description text,
    info_note text,
    feat_note text,
    maori_name character varying(255),
    cpa_legislation text,
    conservancy character varying(255),
    doc_cons_unit_no character varying(255),
    doc_gaz_ref character varying(255),
    treaty_legislation character varying(255),
    geom_type character varying(255),
    accuracy character varying(255),
    gebco character varying(255),
    region character varying(255),
    scufn character varying(255),
    height character varying(255),
    ant_pn_ref character varying(255),
    ant_pgaz_ref character varying(255),
    scar_id character varying(255),
    scar_rec_by character varying(255),
    accuracy_rating character varying(255),
    desc_code character varying(255),
    rev_gaz_ref character varying(255),
    rev_treaty_legislation character varying(255),
    "ref_point_X" double precision,
    "ref_point_Y" double precision,
    "createdBy_id" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    "WKT" geometry(Point,4326),
    is_active boolean DEFAULT true,
    general_link character varying(255),
    code character varying(255),
    boundary geometry(MultiPolygon,4326),
    dist_code character varying(255)
);


ALTER TABLE islands OWNER TO route_guides_production;

--
-- Name: islands_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE islands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE islands_id_seq OWNER TO route_guides_production;

--
-- Name: islands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE islands_id_seq OWNED BY islands.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE items (
    id integer NOT NULL,
    topic_id integer,
    item_type character varying(255),
    item_id integer,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE items OWNER TO route_guides_production;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE items_id_seq OWNER TO route_guides_production;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE items_id_seq OWNED BY items.id;


--
-- Name: legal_roads; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE legal_roads (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    boundary geometry(MultiPolygon,4326)
);


ALTER TABLE legal_roads OWNER TO route_guides_production;

--
-- Name: legal_roads_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE legal_roads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE legal_roads_id_seq OWNER TO route_guides_production;

--
-- Name: legal_roads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE legal_roads_id_seq OWNED BY legal_roads.id;


--
-- Name: lighthouses; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE lighthouses (
    id integer NOT NULL,
    t50_fid character varying(255),
    loc_type character varying(255),
    status character varying(255),
    str_type character varying(255),
    name character varying(255),
    code character varying(255),
    region character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location geometry(Point,4326),
    mnz_id integer
);


ALTER TABLE lighthouses OWNER TO route_guides_production;

--
-- Name: lighthouses_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE lighthouses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE lighthouses_id_seq OWNER TO route_guides_production;

--
-- Name: lighthouses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE lighthouses_id_seq OWNED BY lighthouses.id;


--
-- Name: logs; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE logs (
    id integer NOT NULL,
    callsign1 character varying(255),
    user1_id integer,
    power1 integer,
    signal1 character varying(255),
    transceiver1 character varying(255),
    antenna1 character varying(255),
    comments1 character varying(255),
    first_contact1 boolean DEFAULT true,
    loc_desc1 character varying(255),
    x1 integer,
    y1 integer,
    altitude1 integer,
    date timestamp without time zone,
    "time" timestamp without time zone,
    timezone character varying(255),
    frequency double precision,
    mode character varying(255),
    is_active boolean DEFAULT true,
    "createdBy_id" integer,
    is_qrp1 boolean,
    is_portable1 boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location1 geometry(Point,4326),
    asset_codes character varying(255)[] DEFAULT '{}'::character varying[],
    user_id integer,
    do_not_lookup boolean,
    loc_source character varying(255),
    asset_classes character varying(255)[] DEFAULT '{}'::character varying[],
    qualified boolean[] DEFAULT '{}'::boolean[]
);


ALTER TABLE logs OWNER TO route_guides_production;

--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE logs_id_seq OWNER TO route_guides_production;

--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE logs_id_seq OWNED BY logs.id;


--
-- Name: maplayers; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE maplayers (
    id integer NOT NULL,
    name character varying(255),
    baseurl character varying(255),
    basemap character varying(255),
    maxzoom integer,
    minzoom integer,
    imagetype character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE maplayers OWNER TO route_guides_production;

--
-- Name: maplayers_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE maplayers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE maplayers_id_seq OWNER TO route_guides_production;

--
-- Name: maplayers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE maplayers_id_seq OWNED BY maplayers.id;


--
-- Name: nz_tribal_lands; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE TABLE nz_tribal_lands (
    ogc_fid integer NOT NULL,
    wkb_geometry geometry(MultiPolygon,4326),
    id numeric(10,0),
    name character varying(80)
);


ALTER TABLE nz_tribal_lands OWNER TO mbriggs;

--
-- Name: nz_tribal_lands_ogc_fid_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE nz_tribal_lands_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE nz_tribal_lands_ogc_fid_seq OWNER TO mbriggs;

--
-- Name: nz_tribal_lands_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE nz_tribal_lands_ogc_fid_seq OWNED BY nz_tribal_lands.ogc_fid;


--
-- Name: parks; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE TABLE parks (
    id integer NOT NULL,
    name character varying(255),
    doc_link character varying(255),
    tramper_link character varying(255),
    general_link character varying(255),
    description text,
    is_active boolean DEFAULT true,
    "createdBy_id" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    boundary geometry(MultiPolygon,4326),
    is_mr boolean,
    owner character varying(255),
    location geometry(Point,4326),
    code character varying(255),
    master_id integer,
    dist_code character varying(255),
    land_district character varying(255),
    region character varying(255)
);


ALTER TABLE parks OWNER TO mbriggs;

--
-- Name: parks_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE parks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE parks_id_seq OWNER TO mbriggs;

--
-- Name: parks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE parks_id_seq OWNED BY parks.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE posts (
    id integer NOT NULL,
    title character varying(255),
    description text,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    filename character varying(255),
    image_file_name character varying(255),
    image_content_type character varying(255),
    image_file_size integer,
    image_updated_at timestamp without time zone,
    do_not_publish boolean,
    referenced_datetime timestamp without time zone,
    referenced_date timestamp without time zone,
    referenced_time timestamp without time zone,
    duration integer,
    site character varying(255),
    code character varying(255),
    mode character varying(255),
    freq character varying(255),
    is_hut boolean,
    is_park boolean,
    is_island boolean,
    is_summit boolean,
    hut character varying(255),
    park character varying(255),
    island character varying(255),
    summit character varying(255),
    callsign character varying(255),
    asset_codes character varying(255)[] DEFAULT '{}'::character varying[],
    user_id integer,
    do_not_lookup boolean
);


ALTER TABLE posts OWNER TO route_guides_production;

--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE posts_id_seq OWNER TO route_guides_production;

--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE posts_id_seq OWNED BY posts.id;


--
-- Name: pota_parks; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE pota_parks (
    id integer NOT NULL,
    reference character varying(255),
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location geometry(Point,4326),
    park_id integer
);


ALTER TABLE pota_parks OWNER TO route_guides_production;

--
-- Name: pota_parks_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE pota_parks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE pota_parks_id_seq OWNER TO route_guides_production;

--
-- Name: pota_parks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE pota_parks_id_seq OWNED BY pota_parks.id;


--
-- Name: projections; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE TABLE projections (
    id integer NOT NULL,
    name character varying(255),
    proj4 character varying(255),
    wkt character varying(255),
    epsg integer,
    "createdBy_id" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE projections OWNER TO mbriggs;

--
-- Name: projections_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE projections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE projections_id_seq OWNER TO mbriggs;

--
-- Name: projections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE projections_id_seq OWNED BY projections.id;


--
-- Name: regions; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE regions (
    id integer NOT NULL,
    regc_code character varying(255),
    sota_code character varying(255),
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    boundary geometry(MultiPolygon,4326),
    boundary_quite_simplified geometry(MultiPolygon,4326),
    boundary_simplified geometry(MultiPolygon,4326),
    boundary_very_simplified geometry(MultiPolygon,4326)
);


ALTER TABLE regions OWNER TO route_guides_production;

--
-- Name: regions_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE regions_id_seq OWNER TO route_guides_production;

--
-- Name: regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE regions_id_seq OWNED BY regions.id;


--
-- Name: roads; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE roads (
    id integer NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    linestring geometry(MultiLineString,4326)
);


ALTER TABLE roads OWNER TO route_guides_production;

--
-- Name: roads_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE roads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE roads_id_seq OWNER TO route_guides_production;

--
-- Name: roads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE roads_id_seq OWNED BY roads.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE schema_migrations OWNER TO mbriggs;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE sessions (
    id integer NOT NULL,
    session_id text,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE sessions OWNER TO route_guides_production;

--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sessions_id_seq OWNER TO route_guides_production;

--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE sessions_id_seq OWNED BY sessions.id;


--
-- Name: sota_peaks; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE sota_peaks (
    id integer NOT NULL,
    summit_code character varying(255),
    name character varying(255),
    short_code character varying(255),
    alt character varying(255),
    points integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location geometry(Point,4326),
    valid_from timestamp without time zone,
    valid_to timestamp without time zone
);


ALTER TABLE sota_peaks OWNER TO route_guides_production;

--
-- Name: sota_peaks_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE sota_peaks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sota_peaks_id_seq OWNER TO route_guides_production;

--
-- Name: sota_peaks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE sota_peaks_id_seq OWNED BY sota_peaks.id;


--
-- Name: sota_regions; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE sota_regions (
    id integer NOT NULL,
    dxcc character varying(255),
    region character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE sota_regions OWNER TO route_guides_production;

--
-- Name: sota_regions_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE sota_regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE sota_regions_id_seq OWNER TO route_guides_production;

--
-- Name: sota_regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE sota_regions_id_seq OWNED BY sota_regions.id;


--
-- Name: timezones; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE TABLE timezones (
    id integer NOT NULL,
    name character varying(255),
    description character varying(255),
    difference integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE timezones OWNER TO mbriggs;

--
-- Name: timezones_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE timezones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE timezones_id_seq OWNER TO mbriggs;

--
-- Name: timezones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE timezones_id_seq OWNED BY timezones.id;


--
-- Name: topics; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE topics (
    id integer NOT NULL,
    name character varying(255),
    description text,
    owner_id integer,
    is_public boolean,
    is_owners boolean,
    last_updated timestamp without time zone,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    is_members_only boolean,
    date_required boolean,
    allow_mail boolean,
    duration_required boolean,
    is_alert boolean,
    is_spot boolean,
    allow_attachments boolean
);


ALTER TABLE topics OWNER TO route_guides_production;

--
-- Name: topics_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE topics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE topics_id_seq OWNER TO route_guides_production;

--
-- Name: topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE topics_id_seq OWNED BY topics.id;


--
-- Name: uploads; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE uploads (
    id integer NOT NULL,
    doc_file_name character varying(255),
    doc_content_type character varying(255),
    doc_file_size integer,
    doc_updated_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    doc_callsign character varying(255),
    doc_no_create boolean,
    doc_ignore_error boolean,
    doc_location character varying(255)
);


ALTER TABLE uploads OWNER TO route_guides_production;

--
-- Name: uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE uploads_id_seq OWNER TO route_guides_production;

--
-- Name: uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE uploads_id_seq OWNED BY uploads.id;


--
-- Name: user_callsigns; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE user_callsigns (
    id integer NOT NULL,
    user_id integer,
    callsign character varying(255),
    from_date timestamp without time zone,
    to_date timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE user_callsigns OWNER TO route_guides_production;

--
-- Name: user_callsigns_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE user_callsigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_callsigns_id_seq OWNER TO route_guides_production;

--
-- Name: user_callsigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE user_callsigns_id_seq OWNED BY user_callsigns.id;


--
-- Name: user_topic_links; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE user_topic_links (
    id integer NOT NULL,
    user_id integer,
    topic_id integer,
    mail boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE user_topic_links OWNER TO route_guides_production;

--
-- Name: user_topic_links_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE user_topic_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE user_topic_links_id_seq OWNER TO route_guides_production;

--
-- Name: user_topic_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE user_topic_links_id_seq OWNED BY user_topic_links.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE TABLE users (
    id integer NOT NULL,
    callsign character varying(255),
    email character varying(255),
    firstname character varying(255),
    lastname character varying(255),
    password_digest character varying(255),
    remember_token character varying(255),
    activation_digest character varying(255),
    activated boolean DEFAULT false,
    activated_at timestamp without time zone,
    is_admin boolean DEFAULT false,
    is_active boolean DEFAULT true,
    is_modifier boolean DEFAULT false,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    reset_digest character varying(255),
    reset_sent_at timestamp without time zone,
    timezone integer,
    membership_requested boolean,
    membership_confirmed boolean,
    home_qth character varying(255),
    mailuser character varying(255),
    group_admin boolean,
    remember_token2 character varying(255),
    score character varying(255),
    score_total character varying(255),
    activated_count character varying(255),
    activated_count_total character varying(255),
    chased_count character varying(255),
    chased_count_total character varying(255),
    outstanding boolean,
    pin character varying(255),
    allow_pnp_login boolean,
    hide_news_at timestamp without time zone,
    read_only boolean,
    acctnumber character varying(255),
    logs_pota boolean,
    logs_wwff boolean,
    qualified_count character varying(255),
    qualified_count_total character varying(255),
    confirmed_activated_count character varying(255),
    confirmed_activated_count_total character varying(255)
);


ALTER TABLE users OWNER TO mbriggs;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE users_id_seq OWNER TO mbriggs;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: vk_assets; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE vk_assets (
    id integer NOT NULL,
    award character varying(255),
    wwff_code character varying(255),
    pota_code character varying(255),
    shire_code character varying(255),
    state character varying(255),
    region character varying(255),
    district character varying(255),
    code character varying(255),
    name character varying(255),
    site_type character varying(255),
    latitude double precision,
    longitude double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location geometry(Point,4326)
);


ALTER TABLE vk_assets OWNER TO route_guides_production;

--
-- Name: vk_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE vk_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE vk_assets_id_seq OWNER TO route_guides_production;

--
-- Name: vk_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE vk_assets_id_seq OWNED BY vk_assets.id;


--
-- Name: volcanic_fields; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE volcanic_fields (
    id integer NOT NULL,
    code character varying(255),
    name character varying(255),
    period character varying(255),
    epoch character varying(255),
    eon character varying(255),
    era character varying(255),
    min_age double precision,
    max_age double precision,
    description character varying(255),
    location geometry(Point,4326),
    boundary geometry(MultiPolygon,4326),
    url character varying(255),
    boundary_quite_simplified geometry(MultiPolygon,4326),
    boundary_simplified geometry(MultiPolygon,4326),
    boundary_very_simplified geometry(MultiPolygon,4326)
);


ALTER TABLE volcanic_fields OWNER TO route_guides_production;

--
-- Name: volcanic_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE volcanic_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE volcanic_fields_id_seq OWNER TO route_guides_production;

--
-- Name: volcanic_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE volcanic_fields_id_seq OWNED BY volcanic_fields.id;


--
-- Name: volcanos; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE volcanos (
    id integer NOT NULL,
    code character varying(255),
    name character varying(255),
    status character varying(255),
    field_name character varying(255),
    age double precision,
    period character varying(255),
    epoch character varying(255),
    height integer,
    lat double precision,
    long double precision,
    az_radius double precision,
    url character varying(255),
    description character varying(255),
    location geometry(Point,4326),
    eon character varying(255),
    era character varying(255),
    min_age double precision,
    max_age double precision,
    date_range character varying(255),
    field_code character varying(255)
);


ALTER TABLE volcanos OWNER TO route_guides_production;

--
-- Name: volcanos_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE volcanos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE volcanos_id_seq OWNER TO route_guides_production;

--
-- Name: volcanos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE volcanos_id_seq OWNED BY volcanos.id;


--
-- Name: volcanos_raw; Type: TABLE; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE TABLE volcanos_raw (
    gid integer NOT NULL,
    descr character varying(254),
    typename character varying(50),
    geolhist character varying(254),
    repage_uri character varying(150),
    yngage_uri character varying(150),
    oldage_uri character varying(150),
    stratage character varying(50),
    absmin_ma double precision,
    absmax_ma double precision,
    stratrank character varying(50),
    mbrequiv character varying(150),
    fmnequiv character varying(254),
    sbgrpequiv character varying(150),
    grpequiv character varying(150),
    spgrpequiv character varying(150),
    terrequiv character varying(150),
    megaequiv character varying(150),
    stratlex character varying(100),
    litho2014 character varying(100),
    lithology character varying(150),
    mainrock character varying(50),
    subrocks character varying(150),
    protolith character varying(150),
    tzone character varying(10),
    rockgroup character varying(50),
    rockclass character varying(50),
    simplename character varying(254),
    keygrpname character varying(100),
    volc_name character varying(80),
    group_code character varying(10)
);


ALTER TABLE volcanos_raw OWNER TO mbriggs;

--
-- Name: volcanos_raw_gid_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE volcanos_raw_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE volcanos_raw_gid_seq OWNER TO mbriggs;

--
-- Name: volcanos_raw_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE volcanos_raw_gid_seq OWNED BY volcanos_raw.gid;


--
-- Name: web_link_classes; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE web_link_classes (
    id integer NOT NULL,
    name character varying(255),
    display_name character varying(255),
    url character varying(255),
    is_active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE web_link_classes OWNER TO route_guides_production;

--
-- Name: web_link_classes_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE web_link_classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE web_link_classes_id_seq OWNER TO route_guides_production;

--
-- Name: web_link_classes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE web_link_classes_id_seq OWNED BY web_link_classes.id;


--
-- Name: wwff_parks; Type: TABLE; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE TABLE wwff_parks (
    id integer NOT NULL,
    code character varying(255),
    name character varying(255),
    dxcc character varying(255),
    region character varying(255),
    notes character varying(255),
    napalis_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location geometry(Point,4326)
);


ALTER TABLE wwff_parks OWNER TO route_guides_production;

--
-- Name: wwff_parks_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE wwff_parks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE wwff_parks_id_seq OWNER TO route_guides_production;

--
-- Name: wwff_parks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE wwff_parks_id_seq OWNED BY wwff_parks.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY admin_settings ALTER COLUMN id SET DEFAULT nextval('admin_settings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY ak_maps ALTER COLUMN id SET DEFAULT nextval('ak_maps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY asset_links ALTER COLUMN id SET DEFAULT nextval('asset_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY asset_photo_links ALTER COLUMN id SET DEFAULT nextval('asset_photo_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY asset_types ALTER COLUMN id SET DEFAULT nextval('asset_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY asset_web_links ALTER COLUMN id SET DEFAULT nextval('asset_web_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY assets ALTER COLUMN id SET DEFAULT nextval('assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY award_thresholds ALTER COLUMN id SET DEFAULT nextval('award_thresholds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY award_user_links ALTER COLUMN id SET DEFAULT nextval('award_user_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY awards ALTER COLUMN id SET DEFAULT nextval('awards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY comments ALTER COLUMN id SET DEFAULT nextval('comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY contacts ALTER COLUMN id SET DEFAULT nextval('contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY continents ALTER COLUMN id SET DEFAULT nextval('continents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY crownparks ALTER COLUMN id SET DEFAULT nextval('docparks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY districts ALTER COLUMN id SET DEFAULT nextval('districts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY doc_tracks ALTER COLUMN id SET DEFAULT nextval('doc_tracks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY dxcc_prefixes ALTER COLUMN id SET DEFAULT nextval('dxcc_prefixes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY external_activations ALTER COLUMN id SET DEFAULT nextval('external_activations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY external_chases ALTER COLUMN id SET DEFAULT nextval('external_chases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY external_spots ALTER COLUMN id SET DEFAULT nextval('external_spots_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY geological_eons ALTER COLUMN id SET DEFAULT nextval('geological_eons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY geological_epoches ALTER COLUMN id SET DEFAULT nextval('geological_epoches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY geological_eras ALTER COLUMN id SET DEFAULT nextval('geological_eras_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY geological_periods ALTER COLUMN id SET DEFAULT nextval('geological_periods_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY humps ALTER COLUMN id SET DEFAULT nextval('humps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY huts ALTER COLUMN id SET DEFAULT nextval('huts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY images ALTER COLUMN id SET DEFAULT nextval('images_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY island_polygons ALTER COLUMN id SET DEFAULT nextval('island_polygons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY islands ALTER COLUMN id SET DEFAULT nextval('islands_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY items ALTER COLUMN id SET DEFAULT nextval('items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY legal_roads ALTER COLUMN id SET DEFAULT nextval('legal_roads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY lighthouses ALTER COLUMN id SET DEFAULT nextval('lighthouses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY logs ALTER COLUMN id SET DEFAULT nextval('logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY maplayers ALTER COLUMN id SET DEFAULT nextval('maplayers_id_seq'::regclass);


--
-- Name: ogc_fid; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY nz_tribal_lands ALTER COLUMN ogc_fid SET DEFAULT nextval('nz_tribal_lands_ogc_fid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY parks ALTER COLUMN id SET DEFAULT nextval('parks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY posts ALTER COLUMN id SET DEFAULT nextval('posts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY pota_parks ALTER COLUMN id SET DEFAULT nextval('pota_parks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY projections ALTER COLUMN id SET DEFAULT nextval('projections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY regions ALTER COLUMN id SET DEFAULT nextval('regions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY roads ALTER COLUMN id SET DEFAULT nextval('roads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY sessions ALTER COLUMN id SET DEFAULT nextval('sessions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY sota_peaks ALTER COLUMN id SET DEFAULT nextval('sota_peaks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY sota_regions ALTER COLUMN id SET DEFAULT nextval('sota_regions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY timezones ALTER COLUMN id SET DEFAULT nextval('timezones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY topics ALTER COLUMN id SET DEFAULT nextval('topics_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY uploads ALTER COLUMN id SET DEFAULT nextval('uploads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY user_callsigns ALTER COLUMN id SET DEFAULT nextval('user_callsigns_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY user_topic_links ALTER COLUMN id SET DEFAULT nextval('user_topic_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY vk_assets ALTER COLUMN id SET DEFAULT nextval('vk_assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY volcanic_fields ALTER COLUMN id SET DEFAULT nextval('volcanic_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY volcanos ALTER COLUMN id SET DEFAULT nextval('volcanos_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY volcanos_raw ALTER COLUMN gid SET DEFAULT nextval('volcanos_raw_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY web_link_classes ALTER COLUMN id SET DEFAULT nextval('web_link_classes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY wwff_parks ALTER COLUMN id SET DEFAULT nextval('wwff_parks_id_seq'::regclass);


--
-- Name: admin_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY admin_settings
    ADD CONSTRAINT admin_settings_pkey PRIMARY KEY (id);


--
-- Name: ak_maps_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY ak_maps
    ADD CONSTRAINT ak_maps_pkey PRIMARY KEY (id);


--
-- Name: asset_links_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY asset_links
    ADD CONSTRAINT asset_links_pkey PRIMARY KEY (id);


--
-- Name: asset_photo_links_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY asset_photo_links
    ADD CONSTRAINT asset_photo_links_pkey PRIMARY KEY (id);


--
-- Name: asset_types_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY asset_types
    ADD CONSTRAINT asset_types_pkey PRIMARY KEY (id);


--
-- Name: asset_web_links_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY asset_web_links
    ADD CONSTRAINT asset_web_links_pkey PRIMARY KEY (id);


--
-- Name: assets_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: award_thresholds_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY award_thresholds
    ADD CONSTRAINT award_thresholds_pkey PRIMARY KEY (id);


--
-- Name: award_user_links_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY award_user_links
    ADD CONSTRAINT award_user_links_pkey PRIMARY KEY (id);


--
-- Name: awards_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY awards
    ADD CONSTRAINT awards_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs; Tablespace: 
--

ALTER TABLE ONLY contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: continents_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY continents
    ADD CONSTRAINT continents_pkey PRIMARY KEY (id);


--
-- Name: districts_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- Name: doc_tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY doc_tracks
    ADD CONSTRAINT doc_tracks_pkey PRIMARY KEY (id);


--
-- Name: docparks_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs; Tablespace: 
--

ALTER TABLE ONLY crownparks
    ADD CONSTRAINT docparks_pkey PRIMARY KEY (id);


--
-- Name: dxcc_prefixes_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY dxcc_prefixes
    ADD CONSTRAINT dxcc_prefixes_pkey PRIMARY KEY (id);


--
-- Name: external_spots_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY external_spots
    ADD CONSTRAINT external_spots_pkey PRIMARY KEY (id);


--
-- Name: geological_eons_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY geological_eons
    ADD CONSTRAINT geological_eons_pkey PRIMARY KEY (id);


--
-- Name: geological_epoches_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY geological_epoches
    ADD CONSTRAINT geological_epoches_pkey PRIMARY KEY (id);


--
-- Name: geological_eras_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY geological_eras
    ADD CONSTRAINT geological_eras_pkey PRIMARY KEY (id);


--
-- Name: geological_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY geological_periods
    ADD CONSTRAINT geological_periods_pkey PRIMARY KEY (id);


--
-- Name: humps_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY humps
    ADD CONSTRAINT humps_pkey PRIMARY KEY (id);


--
-- Name: huts_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs; Tablespace: 
--

ALTER TABLE ONLY huts
    ADD CONSTRAINT huts_pkey PRIMARY KEY (id);


--
-- Name: images_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- Name: island_polygons_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY island_polygons
    ADD CONSTRAINT island_polygons_pkey PRIMARY KEY (id);


--
-- Name: islands_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY islands
    ADD CONSTRAINT islands_pkey PRIMARY KEY (id);


--
-- Name: items_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: legal_roads_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY legal_roads
    ADD CONSTRAINT legal_roads_pkey PRIMARY KEY (id);


--
-- Name: lighthouses_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY lighthouses
    ADD CONSTRAINT lighthouses_pkey PRIMARY KEY (id);


--
-- Name: logs_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: maplayers_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY maplayers
    ADD CONSTRAINT maplayers_pkey PRIMARY KEY (id);


--
-- Name: nz_tribal_lands_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs; Tablespace: 
--

ALTER TABLE ONLY nz_tribal_lands
    ADD CONSTRAINT nz_tribal_lands_pkey PRIMARY KEY (ogc_fid);


--
-- Name: parks_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs; Tablespace: 
--

ALTER TABLE ONLY parks
    ADD CONSTRAINT parks_pkey PRIMARY KEY (id);


--
-- Name: posts_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: pota_parks_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY pota_parks
    ADD CONSTRAINT pota_parks_pkey PRIMARY KEY (id);


--
-- Name: projections_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs; Tablespace: 
--

ALTER TABLE ONLY projections
    ADD CONSTRAINT projections_pkey PRIMARY KEY (id);


--
-- Name: regions_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- Name: roads_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY roads
    ADD CONSTRAINT roads_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sota_activations_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY external_activations
    ADD CONSTRAINT sota_activations_pkey PRIMARY KEY (id);


--
-- Name: sota_chases_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY external_chases
    ADD CONSTRAINT sota_chases_pkey PRIMARY KEY (id);


--
-- Name: sota_peaks_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY sota_peaks
    ADD CONSTRAINT sota_peaks_pkey PRIMARY KEY (id);


--
-- Name: sota_regions_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY sota_regions
    ADD CONSTRAINT sota_regions_pkey PRIMARY KEY (id);


--
-- Name: timezones_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs; Tablespace: 
--

ALTER TABLE ONLY timezones
    ADD CONSTRAINT timezones_pkey PRIMARY KEY (id);


--
-- Name: topics_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY topics
    ADD CONSTRAINT topics_pkey PRIMARY KEY (id);


--
-- Name: uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY uploads
    ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);


--
-- Name: user_callsigns_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY user_callsigns
    ADD CONSTRAINT user_callsigns_pkey PRIMARY KEY (id);


--
-- Name: user_topic_links_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY user_topic_links
    ADD CONSTRAINT user_topic_links_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vk_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY vk_assets
    ADD CONSTRAINT vk_assets_pkey PRIMARY KEY (id);


--
-- Name: volcanic_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY volcanic_fields
    ADD CONSTRAINT volcanic_fields_pkey PRIMARY KEY (id);


--
-- Name: volcanos_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY volcanos
    ADD CONSTRAINT volcanos_pkey PRIMARY KEY (id);


--
-- Name: volcanos_raw_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs; Tablespace: 
--

ALTER TABLE ONLY volcanos_raw
    ADD CONSTRAINT volcanos_raw_pkey PRIMARY KEY (gid);


--
-- Name: web_link_classes_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY web_link_classes
    ADD CONSTRAINT web_link_classes_pkey PRIMARY KEY (id);


--
-- Name: wwff_parks_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production; Tablespace: 
--

ALTER TABLE ONLY wwff_parks
    ADD CONSTRAINT wwff_parks_pkey PRIMARY KEY (id);


--
-- Name: assets_boundary_index; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX assets_boundary_index ON assets USING gist (boundary);


--
-- Name: assets_boundary_quite_simplified_index; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX assets_boundary_quite_simplified_index ON assets USING gist (boundary_quite_simplified);


--
-- Name: assets_boundary_simplified_index; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX assets_boundary_simplified_index ON assets USING gist (boundary_simplified);


--
-- Name: assets_boundary_very_simplified_index; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX assets_boundary_very_simplified_index ON assets USING gist (boundary_very_simplified);


--
-- Name: assets_location_index; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX assets_location_index ON assets USING gist (location);


--
-- Name: docparks_wkt_index; Type: INDEX; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE INDEX docparks_wkt_index ON crownparks USING gist ("WKT");


--
-- Name: index_asset_links_on_contained_code; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX index_asset_links_on_contained_code ON asset_links USING btree (contained_code);


--
-- Name: index_asset_links_on_containing_code; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX index_asset_links_on_containing_code ON asset_links USING btree (containing_code);


--
-- Name: index_asset_types_on_name; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX index_asset_types_on_name ON asset_types USING btree (name);


--
-- Name: index_assets_on_asset_type; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX index_assets_on_asset_type ON assets USING btree (asset_type);


--
-- Name: index_assets_on_code; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX index_assets_on_code ON assets USING btree (code);


--
-- Name: index_assets_on_safecode; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX index_assets_on_safecode ON assets USING btree (safecode);


--
-- Name: index_contacts_on_callsign1; Type: INDEX; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE INDEX index_contacts_on_callsign1 ON contacts USING btree (callsign1);


--
-- Name: index_contacts_on_callsign2; Type: INDEX; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE INDEX index_contacts_on_callsign2 ON contacts USING btree (callsign2);


--
-- Name: index_contacts_on_date; Type: INDEX; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE INDEX index_contacts_on_date ON contacts USING btree (date);


--
-- Name: index_logs_on_date; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX index_logs_on_date ON logs USING btree (date);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE UNIQUE INDEX index_sessions_on_session_id ON sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX index_sessions_on_updated_at ON sessions USING btree (updated_at);


--
-- Name: index_users_on_callsign; Type: INDEX; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE INDEX index_users_on_callsign ON users USING btree (callsign);


--
-- Name: index_users_on_remember_token; Type: INDEX; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE INDEX index_users_on_remember_token ON users USING btree (remember_token);


--
-- Name: nz_tribal_lands_wkb_geometry_geom_idx; Type: INDEX; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE INDEX nz_tribal_lands_wkb_geometry_geom_idx ON nz_tribal_lands USING gist (wkb_geometry);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: mbriggs; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: vk_award_indx; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX vk_award_indx ON vk_assets USING btree (award);


--
-- Name: vk_code_indx; Type: INDEX; Schema: public; Owner: route_guides_production; Tablespace: 
--

CREATE INDEX vk_code_indx ON vk_assets USING btree (code);


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

