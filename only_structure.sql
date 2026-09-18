--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.25
-- Dumped by pg_dump version 9.5.25

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: EXTENSION btree_gist; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION btree_gist IS 'support for indexing common datatypes in GiST';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


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


--
-- Name: st_cardinaldirection(double precision); Type: FUNCTION; Schema: public; Owner: mbriggs
--

CREATE FUNCTION public.st_cardinaldirection(azimuth double precision) RETURNS character varying
    LANGUAGE sql IMMUTABLE
    AS $_$SELECT CASE
  WHEN $1 < 0.0 THEN 'less than 0'
  WHEN degrees($1) < 22.5 THEN 'N'
  WHEN degrees($1) < 67.5 THEN 'NE'
  WHEN degrees($1) < 112.5 THEN 'E'
  WHEN degrees($1) < 157.5 THEN 'SE'
  WHEN degrees($1) < 202.5 THEN 'S'
  WHEN degrees($1) < 247.5 THEN 'SW'
  WHEN degrees($1) < 292.5 THEN 'W'
  WHEN degrees($1) < 337.5 THEN 'NW'
  WHEN degrees($1) <= 360.0 THEN 'N'
END;$_$;


ALTER FUNCTION public.st_cardinaldirection(azimuth double precision) OWNER TO mbriggs;

--
-- Name: FUNCTION st_cardinaldirection(azimuth double precision); Type: COMMENT; Schema: public; Owner: mbriggs
--

COMMENT ON FUNCTION public.st_cardinaldirection(azimuth double precision) IS 'input azimuth in radians; returns N, NW, W, SW, S, SE, E, or NE';


--
-- Name: utmzone(public.geometry); Type: FUNCTION; Schema: public; Owner: mbriggs
--

CREATE FUNCTION public.utmzone(public.geometry) RETURNS integer
    LANGUAGE plpgsql IMMUTABLE
    AS $_$
 DECLARE
     geomgeog geometry;
     zone int;
     pref int;

 BEGIN
     geomgeog:= ST_Transform($1,4326);

     IF (ST_Y(geomgeog))>0 THEN
        pref:=32600;
     ELSE
        pref:=32700;
     END IF;

     zone:=floor((ST_X(geomgeog)+180)/6)+1;

     RETURN zone+pref;
 END;
 $_$;


ALTER FUNCTION public.utmzone(public.geometry) OWNER TO mbriggs;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: admin_settings; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.admin_settings (
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
    sota_epoch character varying(255),
    default_projection text,
    default_layer text,
    default_x text,
    default_y text,
    title text,
    name text,
    imagepath text,
    sota_alert_epoch character varying(255),
    last_minute_sched_at timestamp without time zone,
    last_monthly_sched_at timestamp without time zone,
    last_sota_update_id character varying(255),
    last_pota_update_id character varying(255)
);


ALTER TABLE public.admin_settings OWNER TO route_guides_production;

--
-- Name: admin_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.admin_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admin_settings_id_seq OWNER TO route_guides_production;

--
-- Name: admin_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.admin_settings_id_seq OWNED BY public.admin_settings.id;


--
-- Name: ak_maps; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.ak_maps (
    id integer NOT NULL,
    name character varying(255),
    code character varying(255),
    "WKT" public.geometry(MultiPolygon,4326),
    location public.geometry(Point,4326)
);


ALTER TABLE public.ak_maps OWNER TO route_guides_production;

--
-- Name: ak_maps_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.ak_maps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ak_maps_id_seq OWNER TO route_guides_production;

--
-- Name: ak_maps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.ak_maps_id_seq OWNED BY public.ak_maps.id;


--
-- Name: asset_links; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.asset_links (
    id integer NOT NULL,
    contained_code character varying(255),
    containing_code character varying(255),
    overlap double precision
);


ALTER TABLE public.asset_links OWNER TO route_guides_production;

--
-- Name: asset_links_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.asset_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.asset_links_id_seq OWNER TO route_guides_production;

--
-- Name: asset_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.asset_links_id_seq OWNED BY public.asset_links.id;


--
-- Name: asset_photo_links; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.asset_photo_links (
    id integer NOT NULL,
    asset_code character varying(255),
    link_url character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    photo_id integer
);


ALTER TABLE public.asset_photo_links OWNER TO route_guides_production;

--
-- Name: asset_photo_links_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.asset_photo_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.asset_photo_links_id_seq OWNER TO route_guides_production;

--
-- Name: asset_photo_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.asset_photo_links_id_seq OWNED BY public.asset_photo_links.id;


--
-- Name: asset_types; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.asset_types (
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
    use_volcanic_field boolean,
    use_az boolean,
    use_within_sight boolean,
    like_pattern character varying(255)
);


ALTER TABLE public.asset_types OWNER TO route_guides_production;

--
-- Name: asset_types_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.asset_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.asset_types_id_seq OWNER TO route_guides_production;

--
-- Name: asset_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.asset_types_id_seq OWNED BY public.asset_types.id;


--
-- Name: asset_web_links; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.asset_web_links (
    id integer NOT NULL,
    asset_code character varying(255),
    url character varying(255),
    link_class character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.asset_web_links OWNER TO route_guides_production;

--
-- Name: asset_web_links_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.asset_web_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.asset_web_links_id_seq OWNER TO route_guides_production;

--
-- Name: asset_web_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.asset_web_links_id_seq OWNED BY public.asset_web_links.id;


--
-- Name: assets; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.assets (
    id integer NOT NULL,
    asset_type character varying(255),
    code character varying(255),
    url character varying(255),
    name character varying(255),
    is_active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    boundary public.geometry(MultiPolygon,4326),
    location public.geometry(Point,4326),
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
    boundary_quite_simplified public.geometry(MultiPolygon,4326),
    boundary_simplified public.geometry(MultiPolygon,4326),
    boundary_very_simplified public.geometry(MultiPolygon,4326),
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
    field_code character varying(255),
    az_boundary public.geometry(MultiPolygon,4326),
    az_area double precision,
    country character varying(255),
    state character varying(255),
    access_capad_park_ids character varying(255)[] DEFAULT '{}'::character varying[],
    access_vk_state_park_ids character varying(255)[] DEFAULT '{}'::character varying[]
);


ALTER TABLE public.assets OWNER TO route_guides_production;

--
-- Name: assets_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assets_id_seq OWNER TO route_guides_production;

--
-- Name: assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.assets_id_seq OWNED BY public.assets.id;


--
-- Name: award_thresholds; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.award_thresholds (
    id integer NOT NULL,
    threshold integer,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.award_thresholds OWNER TO route_guides_production;

--
-- Name: award_thresholds_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.award_thresholds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.award_thresholds_id_seq OWNER TO route_guides_production;

--
-- Name: award_thresholds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.award_thresholds_id_seq OWNED BY public.award_thresholds.id;


--
-- Name: award_user_links; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.award_user_links (
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


ALTER TABLE public.award_user_links OWNER TO route_guides_production;

--
-- Name: award_user_links_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.award_user_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.award_user_links_id_seq OWNER TO route_guides_production;

--
-- Name: award_user_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.award_user_links_id_seq OWNED BY public.award_user_links.id;


--
-- Name: awards; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.awards (
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


ALTER TABLE public.awards OWNER TO route_guides_production;

--
-- Name: awards_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.awards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.awards_id_seq OWNER TO route_guides_production;

--
-- Name: awards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.awards_id_seq OWNED BY public.awards.id;


--
-- Name: bands; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.bands (
    id integer NOT NULL,
    meter_band character varying(255),
    freq_band character varying(255),
    "group" character varying(255),
    min_frequency double precision,
    max_frequency double precision
);


ALTER TABLE public.bands OWNER TO route_guides_production;

--
-- Name: bands_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.bands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.bands_id_seq OWNER TO route_guides_production;

--
-- Name: bands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.bands_id_seq OWNED BY public.bands.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.comments (
    id integer NOT NULL,
    comment text,
    code character varying(255),
    updated_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.comments OWNER TO route_guides_production;

--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comments_id_seq OWNER TO route_guides_production;

--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: consolidated_spots; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.consolidated_spots (
    id integer NOT NULL,
    "time" character varying(255)[] DEFAULT '{}'::character varying[],
    callsign character varying(255)[] DEFAULT '{}'::character varying[],
    "activatorCallsign" character varying(255),
    code character varying(255)[] DEFAULT '{}'::character varying[],
    name character varying(255)[] DEFAULT '{}'::character varying[],
    frequency character varying(255),
    mode character varying(255),
    comments character varying(255)[] DEFAULT '{}'::character varying[],
    spot_type character varying(255)[] DEFAULT '{}'::character varying[],
    post_id character varying(255)[] DEFAULT '{}'::character varying[],
    points character varying(255),
    "altM" character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    old_spot_type character varying(255)[] DEFAULT '{}'::character varying[],
    band character varying(255),
    dxcc character varying(255),
    continent character varying(255)
);


ALTER TABLE public.consolidated_spots OWNER TO route_guides_production;

--
-- Name: consolidated_spots_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.consolidated_spots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.consolidated_spots_id_seq OWNER TO route_guides_production;

--
-- Name: consolidated_spots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.consolidated_spots_id_seq OWNED BY public.consolidated_spots.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: mbriggs
--

CREATE TABLE public.contacts (
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
    location1 public.geometry(Point,4326),
    location2 public.geometry(Point,4326),
    is_qrp1 boolean,
    is_portable1 boolean,
    is_qrp2 boolean,
    is_portable2 boolean,
    log_id integer,
    asset1_codes character varying(255)[] DEFAULT '{}'::character varying[],
    asset2_codes character varying(255)[] DEFAULT '{}'::character varying[],
    name1 character varying(255),
    name2 character varying(255),
    asset1_classes character varying(255)[] DEFAULT '{}'::character varying[],
    asset2_classes character varying(255)[] DEFAULT '{}'::character varying[],
    band character varying(255),
    loc_source2 character varying(255),
    do_not_lookup boolean,
    submitted_to character varying(255)[] DEFAULT '{}'::character varying[]
);


ALTER TABLE public.contacts OWNER TO mbriggs;

--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.contacts_id_seq OWNER TO mbriggs;

--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: continents; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.continents (
    id integer NOT NULL,
    name character varying(255),
    code character varying(255)
);


ALTER TABLE public.continents OWNER TO route_guides_production;

--
-- Name: continents_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.continents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.continents_id_seq OWNER TO route_guides_production;

--
-- Name: continents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.continents_id_seq OWNED BY public.continents.id;


SET default_with_oids = true;

--
-- Name: crownparks; Type: TABLE; Schema: public; Owner: mbriggs
--

CREATE TABLE public.crownparks (
    "WKT" public.geometry(MultiPolygon,4326),
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


ALTER TABLE public.crownparks OWNER TO mbriggs;

SET default_with_oids = false;

--
-- Name: districts; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.districts (
    id integer NOT NULL,
    district_code character varying(255),
    region_code character varying(255),
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    boundary public.geometry(MultiPolygon,4326),
    boundary_quite_simplified public.geometry(MultiPolygon,4326),
    boundary_simplified public.geometry(MultiPolygon,4326),
    boundary_very_simplified public.geometry(MultiPolygon,4326),
    dxcc character varying(255),
    state_code character varying(255)
);


ALTER TABLE public.districts OWNER TO route_guides_production;

--
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.districts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.districts_id_seq OWNER TO route_guides_production;

--
-- Name: districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.districts_id_seq OWNED BY public.districts.id;


--
-- Name: doc_tracks; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.doc_tracks (
    id integer NOT NULL,
    name character varying(255),
    object_type character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    linestring public.geometry(MultiLineString,4326)
);


ALTER TABLE public.doc_tracks OWNER TO route_guides_production;

--
-- Name: doc_tracks_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.doc_tracks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.doc_tracks_id_seq OWNER TO route_guides_production;

--
-- Name: doc_tracks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.doc_tracks_id_seq OWNED BY public.doc_tracks.id;


--
-- Name: docparks_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE public.docparks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.docparks_id_seq OWNER TO mbriggs;

--
-- Name: docparks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE public.docparks_id_seq OWNED BY public.crownparks.id;


--
-- Name: dxcc_prefixes; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.dxcc_prefixes (
    id integer NOT NULL,
    name character varying(255),
    prefix character varying(255),
    itu_zone character varying(255),
    cq_zone character varying(255),
    continent_code character varying(255),
    dxcc_enum character varying(255),
    is_active boolean,
    iso_code character varying(255),
    sms_gateway character varying(255)
);


ALTER TABLE public.dxcc_prefixes OWNER TO route_guides_production;

--
-- Name: dxcc_prefixes_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.dxcc_prefixes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.dxcc_prefixes_id_seq OWNER TO route_guides_production;

--
-- Name: dxcc_prefixes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.dxcc_prefixes_id_seq OWNED BY public.dxcc_prefixes.id;


--
-- Name: email_blacklists; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.email_blacklists (
    id integer NOT NULL,
    email_provider character varying(255)
);


ALTER TABLE public.email_blacklists OWNER TO route_guides_production;

--
-- Name: email_blacklists_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.email_blacklists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.email_blacklists_id_seq OWNER TO route_guides_production;

--
-- Name: email_blacklists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.email_blacklists_id_seq OWNED BY public.email_blacklists.id;


--
-- Name: external_activations; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.external_activations (
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


ALTER TABLE public.external_activations OWNER TO route_guides_production;

--
-- Name: external_activations_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.external_activations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.external_activations_id_seq OWNER TO route_guides_production;

--
-- Name: external_activations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.external_activations_id_seq OWNED BY public.external_activations.id;


--
-- Name: external_alerts; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.external_alerts (
    id integer NOT NULL,
    starttime timestamp without time zone,
    "activatingCallsign" character varying(255),
    code character varying(255),
    name character varying(255),
    frequency character varying(255),
    comments character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    mode character varying(255),
    programme character varying(255),
    duration character varying(255),
    dxcc character varying(255),
    continent character varying(255)
);


ALTER TABLE public.external_alerts OWNER TO route_guides_production;

--
-- Name: external_alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.external_alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.external_alerts_id_seq OWNER TO route_guides_production;

--
-- Name: external_alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.external_alerts_id_seq OWNED BY public.external_alerts.id;


--
-- Name: external_chases; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.external_chases (
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


ALTER TABLE public.external_chases OWNER TO route_guides_production;

--
-- Name: external_chases_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.external_chases_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.external_chases_id_seq OWNER TO route_guides_production;

--
-- Name: external_chases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.external_chases_id_seq OWNED BY public.external_chases.id;


--
-- Name: external_spots; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.external_spots (
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
    "altM" character varying(255),
    is_pnp boolean
);


ALTER TABLE public.external_spots OWNER TO route_guides_production;

--
-- Name: external_spots_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.external_spots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.external_spots_id_seq OWNER TO route_guides_production;

--
-- Name: external_spots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.external_spots_id_seq OWNED BY public.external_spots.id;


--
-- Name: geological_eons; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.geological_eons (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.geological_eons OWNER TO route_guides_production;

--
-- Name: geological_eons_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.geological_eons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.geological_eons_id_seq OWNER TO route_guides_production;

--
-- Name: geological_eons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.geological_eons_id_seq OWNED BY public.geological_eons.id;


--
-- Name: geological_epoches; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.geological_epoches (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.geological_epoches OWNER TO route_guides_production;

--
-- Name: geological_epoches_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.geological_epoches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.geological_epoches_id_seq OWNER TO route_guides_production;

--
-- Name: geological_epoches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.geological_epoches_id_seq OWNED BY public.geological_epoches.id;


--
-- Name: geological_eras; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.geological_eras (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.geological_eras OWNER TO route_guides_production;

--
-- Name: geological_eras_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.geological_eras_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.geological_eras_id_seq OWNER TO route_guides_production;

--
-- Name: geological_eras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.geological_eras_id_seq OWNED BY public.geological_eras.id;


--
-- Name: geological_periods; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.geological_periods (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.geological_periods OWNER TO route_guides_production;

--
-- Name: geological_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.geological_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.geological_periods_id_seq OWNER TO route_guides_production;

--
-- Name: geological_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.geological_periods_id_seq OWNED BY public.geological_periods.id;


--
-- Name: humps; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.humps (
    id integer NOT NULL,
    dxcc character varying(255),
    region character varying(255),
    code character varying(255),
    name character varying(255),
    elevation character varying(255),
    prominence character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location public.geometry(Point,4326)
);


ALTER TABLE public.humps OWNER TO route_guides_production;

--
-- Name: humps_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.humps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.humps_id_seq OWNER TO route_guides_production;

--
-- Name: humps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.humps_id_seq OWNED BY public.humps.id;


--
-- Name: huts; Type: TABLE; Schema: public; Owner: mbriggs
--

CREATE TABLE public.huts (
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
    location public.geometry(Point,4326),
    code character varying(255),
    region character varying(255),
    dist_code character varying(255)
);


ALTER TABLE public.huts OWNER TO mbriggs;

--
-- Name: huts_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE public.huts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.huts_id_seq OWNER TO mbriggs;

--
-- Name: huts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE public.huts_id_seq OWNED BY public.huts.id;


--
-- Name: images; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.images (
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


ALTER TABLE public.images OWNER TO route_guides_production;

--
-- Name: images_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.images_id_seq OWNER TO route_guides_production;

--
-- Name: images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.images_id_seq OWNED BY public.images.id;


--
-- Name: island_polygons; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.island_polygons (
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
    "WKT" public.geometry(MultiPolygon,4326)
);


ALTER TABLE public.island_polygons OWNER TO route_guides_production;

--
-- Name: island_polygons_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.island_polygons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.island_polygons_id_seq OWNER TO route_guides_production;

--
-- Name: island_polygons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.island_polygons_id_seq OWNED BY public.island_polygons.id;


--
-- Name: islands; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.islands (
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
    "WKT" public.geometry(Point,4326),
    is_active boolean DEFAULT true,
    general_link character varying(255),
    code character varying(255),
    boundary public.geometry(MultiPolygon,4326),
    dist_code character varying(255)
);


ALTER TABLE public.islands OWNER TO route_guides_production;

--
-- Name: islands_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.islands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.islands_id_seq OWNER TO route_guides_production;

--
-- Name: islands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.islands_id_seq OWNED BY public.islands.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.items (
    id integer NOT NULL,
    topic_id integer,
    item_type character varying(255),
    item_id integer,
    created_by_id integer,
    updated_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.items OWNER TO route_guides_production;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.items_id_seq OWNER TO route_guides_production;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: legal_roads; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.legal_roads (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    boundary public.geometry(MultiPolygon,4326)
);


ALTER TABLE public.legal_roads OWNER TO route_guides_production;

--
-- Name: legal_roads_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.legal_roads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.legal_roads_id_seq OWNER TO route_guides_production;

--
-- Name: legal_roads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.legal_roads_id_seq OWNED BY public.legal_roads.id;


--
-- Name: lighthouses; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.lighthouses (
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
    location public.geometry(Point,4326),
    mnz_id integer
);


ALTER TABLE public.lighthouses OWNER TO route_guides_production;

--
-- Name: lighthouses_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.lighthouses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.lighthouses_id_seq OWNER TO route_guides_production;

--
-- Name: lighthouses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.lighthouses_id_seq OWNED BY public.lighthouses.id;


--
-- Name: logs; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.logs (
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
    location1 public.geometry(Point,4326),
    asset_codes character varying(255)[] DEFAULT '{}'::character varying[],
    user_id integer,
    do_not_lookup boolean,
    loc_source character varying(255),
    asset_classes character varying(255)[] DEFAULT '{}'::character varying[],
    qualified boolean[] DEFAULT '{}'::boolean[]
);


ALTER TABLE public.logs OWNER TO route_guides_production;

--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.logs_id_seq OWNER TO route_guides_production;

--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.logs_id_seq OWNED BY public.logs.id;


--
-- Name: maplayers; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.maplayers (
    id integer NOT NULL,
    name character varying(255),
    baseurl character varying(255),
    basemap character varying(255),
    maxzoom integer,
    minzoom integer,
    imagetype character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    copyright_text character varying(255),
    copyright_link character varying(255),
    extent character varying(255)
);


ALTER TABLE public.maplayers OWNER TO route_guides_production;

--
-- Name: maplayers_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.maplayers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.maplayers_id_seq OWNER TO route_guides_production;

--
-- Name: maplayers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.maplayers_id_seq OWNED BY public.maplayers.id;


--
-- Name: nz_tribal_lands; Type: TABLE; Schema: public; Owner: mbriggs
--

CREATE TABLE public.nz_tribal_lands (
    ogc_fid integer NOT NULL,
    wkb_geometry public.geometry(MultiPolygon,4326),
    id numeric(10,0),
    name character varying(80),
    country character varying(255),
    boundary_quite_simplified public.geometry(MultiPolygon,4326),
    boundary_simplified public.geometry(MultiPolygon,4326),
    boundary_very_simplified public.geometry(MultiPolygon,4326)
);


ALTER TABLE public.nz_tribal_lands OWNER TO mbriggs;

--
-- Name: nz_tribal_lands_ogc_fid_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE public.nz_tribal_lands_ogc_fid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.nz_tribal_lands_ogc_fid_seq OWNER TO mbriggs;

--
-- Name: nz_tribal_lands_ogc_fid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE public.nz_tribal_lands_ogc_fid_seq OWNED BY public.nz_tribal_lands.ogc_fid;


--
-- Name: parks; Type: TABLE; Schema: public; Owner: mbriggs
--

CREATE TABLE public.parks (
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
    boundary public.geometry(MultiPolygon,4326),
    is_mr boolean,
    owner character varying(255),
    location public.geometry(Point,4326),
    code character varying(255),
    master_id integer,
    dist_code character varying(255),
    land_district character varying(255),
    region character varying(255)
);


ALTER TABLE public.parks OWNER TO mbriggs;

--
-- Name: parks_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE public.parks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.parks_id_seq OWNER TO mbriggs;

--
-- Name: parks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE public.parks_id_seq OWNED BY public.parks.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.posts (
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
    do_not_lookup boolean,
    location public.geometry(Point,4326),
    loc_source character varying(255)
);


ALTER TABLE public.posts OWNER TO route_guides_production;

--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.posts_id_seq OWNER TO route_guides_production;

--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: pota_parks; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.pota_parks (
    id integer NOT NULL,
    reference character varying(255),
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location public.geometry(Point,4326),
    park_id integer
);


ALTER TABLE public.pota_parks OWNER TO route_guides_production;

--
-- Name: pota_parks_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.pota_parks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pota_parks_id_seq OWNER TO route_guides_production;

--
-- Name: pota_parks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.pota_parks_id_seq OWNED BY public.pota_parks.id;


--
-- Name: projections; Type: TABLE; Schema: public; Owner: mbriggs
--

CREATE TABLE public.projections (
    id integer NOT NULL,
    name character varying(255),
    proj4 character varying(255),
    wkt character varying(255),
    epsg integer,
    "createdBy_id" integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.projections OWNER TO mbriggs;

--
-- Name: projections_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE public.projections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projections_id_seq OWNER TO mbriggs;

--
-- Name: projections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE public.projections_id_seq OWNED BY public.projections.id;


--
-- Name: ratings; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.ratings (
    id integer NOT NULL,
    drive_up_access boolean,
    track_access boolean,
    accessibility_score integer,
    nice_score integer,
    user_id integer,
    asset_code character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.ratings OWNER TO route_guides_production;

--
-- Name: ratings_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.ratings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ratings_id_seq OWNER TO route_guides_production;

--
-- Name: ratings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.ratings_id_seq OWNED BY public.ratings.id;


--
-- Name: regions; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.regions (
    id integer NOT NULL,
    regc_code character varying(255),
    sota_code character varying(255),
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    boundary public.geometry(MultiPolygon,4326),
    boundary_quite_simplified public.geometry(MultiPolygon,4326),
    boundary_simplified public.geometry(MultiPolygon,4326),
    boundary_very_simplified public.geometry(MultiPolygon,4326),
    dxcc character varying(255),
    state_code character varying(255)
);


ALTER TABLE public.regions OWNER TO route_guides_production;

--
-- Name: regions_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.regions_id_seq OWNER TO route_guides_production;

--
-- Name: regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.regions_id_seq OWNED BY public.regions.id;


--
-- Name: roads; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.roads (
    id bigint NOT NULL,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    linestring public.geometry(MultiLineString,4326)
);


ALTER TABLE public.roads OWNER TO route_guides_production;

--
-- Name: roads_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.roads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.roads_id_seq OWNER TO route_guides_production;

--
-- Name: roads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.roads_id_seq OWNED BY public.roads.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: mbriggs
--

CREATE TABLE public.schema_migrations (
    version character varying(255) NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO mbriggs;

--
-- Name: sessions; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.sessions (
    id integer NOT NULL,
    session_id text,
    data text,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.sessions OWNER TO route_guides_production;

--
-- Name: sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sessions_id_seq OWNER TO route_guides_production;

--
-- Name: sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.sessions_id_seq OWNED BY public.sessions.id;


--
-- Name: sota_peaks; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.sota_peaks (
    id integer NOT NULL,
    summit_code character varying(255),
    name character varying(255),
    short_code character varying(255),
    alt character varying(255),
    points integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location public.geometry(Point,4326),
    valid_from timestamp without time zone,
    valid_to timestamp without time zone
);


ALTER TABLE public.sota_peaks OWNER TO route_guides_production;

--
-- Name: sota_peaks_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.sota_peaks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sota_peaks_id_seq OWNER TO route_guides_production;

--
-- Name: sota_peaks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.sota_peaks_id_seq OWNED BY public.sota_peaks.id;


--
-- Name: sota_regions; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.sota_regions (
    id integer NOT NULL,
    dxcc character varying(255),
    region character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.sota_regions OWNER TO route_guides_production;

--
-- Name: sota_regions_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.sota_regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sota_regions_id_seq OWNER TO route_guides_production;

--
-- Name: sota_regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.sota_regions_id_seq OWNED BY public.sota_regions.id;


--
-- Name: states; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.states (
    id integer NOT NULL,
    code character varying(255),
    pnp_code character varying(255),
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    dxcc character varying(255),
    boundary public.geometry(MultiPolygon,4326),
    boundary_quite_simplified public.geometry(MultiPolygon,4326),
    boundary_simplified public.geometry(MultiPolygon,4326),
    boundary_very_simplified public.geometry(MultiPolygon,4326)
);


ALTER TABLE public.states OWNER TO route_guides_production;

--
-- Name: states_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.states_id_seq OWNER TO route_guides_production;

--
-- Name: states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.states_id_seq OWNED BY public.states.id;


--
-- Name: timezones; Type: TABLE; Schema: public; Owner: mbriggs
--

CREATE TABLE public.timezones (
    id integer NOT NULL,
    name character varying(255),
    description character varying(255),
    difference integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.timezones OWNER TO mbriggs;

--
-- Name: timezones_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE public.timezones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.timezones_id_seq OWNER TO mbriggs;

--
-- Name: timezones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE public.timezones_id_seq OWNED BY public.timezones.id;


--
-- Name: topics; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.topics (
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


ALTER TABLE public.topics OWNER TO route_guides_production;

--
-- Name: topics_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.topics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.topics_id_seq OWNER TO route_guides_production;

--
-- Name: topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.topics_id_seq OWNED BY public.topics.id;


--
-- Name: uploads; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.uploads (
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


ALTER TABLE public.uploads OWNER TO route_guides_production;

--
-- Name: uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.uploads_id_seq OWNER TO route_guides_production;

--
-- Name: uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.uploads_id_seq OWNED BY public.uploads.id;


--
-- Name: user_agents; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.user_agents (
    id integer NOT NULL,
    access_count integer DEFAULT 0 NOT NULL,
    user_ip text NOT NULL,
    suspected_bot boolean,
    confirmed_bot boolean,
    suspicious_access_count integer DEFAULT 0 NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    html_count integer DEFAULT 0 NOT NULL,
    js_count integer DEFAULT 0 NOT NULL,
    confirmed_human boolean
);


ALTER TABLE public.user_agents OWNER TO route_guides_production;

--
-- Name: user_agents_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.user_agents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_agents_id_seq OWNER TO route_guides_production;

--
-- Name: user_agents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.user_agents_id_seq OWNED BY public.user_agents.id;


--
-- Name: user_callsigns; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.user_callsigns (
    id integer NOT NULL,
    user_id integer,
    callsign character varying(255),
    from_date timestamp without time zone,
    to_date timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.user_callsigns OWNER TO route_guides_production;

--
-- Name: user_callsigns_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.user_callsigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_callsigns_id_seq OWNER TO route_guides_production;

--
-- Name: user_callsigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.user_callsigns_id_seq OWNED BY public.user_callsigns.id;


--
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.user_tokens (
    id integer NOT NULL,
    remember_token character varying(255),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.user_tokens OWNER TO route_guides_production;

--
-- Name: user_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.user_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_tokens_id_seq OWNER TO route_guides_production;

--
-- Name: user_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.user_tokens_id_seq OWNED BY public.user_tokens.id;


--
-- Name: user_topic_links; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.user_topic_links (
    id integer NOT NULL,
    user_id integer,
    topic_id integer,
    mail boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    notification boolean
);


ALTER TABLE public.user_topic_links OWNER TO route_guides_production;

--
-- Name: user_topic_links_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.user_topic_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_topic_links_id_seq OWNER TO route_guides_production;

--
-- Name: user_topic_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.user_topic_links_id_seq OWNED BY public.user_topic_links.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: mbriggs
--

CREATE TABLE public.users (
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
    confirmed_activated_count_total character varying(255),
    polygonlayers character varying(255),
    pointlayers character varying(255),
    is_web_admin boolean,
    push_app_token character varying(255),
    push_user_token character varying(255),
    push_include_comments boolean,
    push_include_map boolean,
    push_external_filter character varying(255),
    push_include_external boolean,
    dxcc character varying(255),
    baselayer character varying(255),
    "pnp_APIKey" character varying(255),
    pnp_imported boolean DEFAULT false,
    pnp_username character varying(255),
    pnp_status character varying(255)
);


ALTER TABLE public.users OWNER TO mbriggs;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO mbriggs;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vk_assets; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.vk_assets (
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
    location public.geometry(Point,4326),
    boundary public.geometry(MultiPolygon,4326),
    boundary_quite_simplified public.geometry(MultiPolygon,4326),
    boundary_simplified public.geometry(MultiPolygon,4326),
    boundary_very_simplified public.geometry(MultiPolygon,4326),
    caped_id integer,
    area double precision,
    is_active boolean,
    url character varying(255),
    asset_type character varying(255),
    description text,
    old_code character varying(255)
);


ALTER TABLE public.vk_assets OWNER TO route_guides_production;

--
-- Name: vk_assets_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.vk_assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.vk_assets_id_seq OWNER TO route_guides_production;

--
-- Name: vk_assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.vk_assets_id_seq OWNED BY public.vk_assets.id;


--
-- Name: vk_lakes; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.vk_lakes (
    id integer NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.vk_lakes OWNER TO route_guides_production;

--
-- Name: vk_lakes_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.vk_lakes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.vk_lakes_id_seq OWNER TO route_guides_production;

--
-- Name: vk_lakes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.vk_lakes_id_seq OWNED BY public.vk_lakes.id;


--
-- Name: volcanic_fields; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.volcanic_fields (
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
    location public.geometry(Point,4326),
    boundary public.geometry(MultiPolygon,4326),
    url character varying(255),
    boundary_quite_simplified public.geometry(MultiPolygon,4326),
    boundary_simplified public.geometry(MultiPolygon,4326),
    boundary_very_simplified public.geometry(MultiPolygon,4326)
);


ALTER TABLE public.volcanic_fields OWNER TO route_guides_production;

--
-- Name: volcanic_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.volcanic_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.volcanic_fields_id_seq OWNER TO route_guides_production;

--
-- Name: volcanic_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.volcanic_fields_id_seq OWNED BY public.volcanic_fields.id;


--
-- Name: volcanos; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.volcanos (
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
    location public.geometry(Point,4326),
    eon character varying(255),
    era character varying(255),
    min_age double precision,
    max_age double precision,
    date_range character varying(255),
    field_code character varying(255)
);


ALTER TABLE public.volcanos OWNER TO route_guides_production;

--
-- Name: volcanos_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.volcanos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.volcanos_id_seq OWNER TO route_guides_production;

--
-- Name: volcanos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.volcanos_id_seq OWNED BY public.volcanos.id;


--
-- Name: volcanos_raw; Type: TABLE; Schema: public; Owner: mbriggs
--

CREATE TABLE public.volcanos_raw (
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


ALTER TABLE public.volcanos_raw OWNER TO mbriggs;

--
-- Name: volcanos_raw_gid_seq; Type: SEQUENCE; Schema: public; Owner: mbriggs
--

CREATE SEQUENCE public.volcanos_raw_gid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.volcanos_raw_gid_seq OWNER TO mbriggs;

--
-- Name: volcanos_raw_gid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: mbriggs
--

ALTER SEQUENCE public.volcanos_raw_gid_seq OWNED BY public.volcanos_raw.gid;


--
-- Name: web_link_classes; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.web_link_classes (
    id integer NOT NULL,
    name character varying(255),
    display_name character varying(255),
    url character varying(255),
    is_active boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.web_link_classes OWNER TO route_guides_production;

--
-- Name: web_link_classes_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.web_link_classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.web_link_classes_id_seq OWNER TO route_guides_production;

--
-- Name: web_link_classes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.web_link_classes_id_seq OWNED BY public.web_link_classes.id;


--
-- Name: wishlists; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.wishlists (
    id integer NOT NULL,
    asset_code character varying(255),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


ALTER TABLE public.wishlists OWNER TO route_guides_production;

--
-- Name: wishlists_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.wishlists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.wishlists_id_seq OWNER TO route_guides_production;

--
-- Name: wishlists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.wishlists_id_seq OWNED BY public.wishlists.id;


--
-- Name: wwff_parks; Type: TABLE; Schema: public; Owner: route_guides_production
--

CREATE TABLE public.wwff_parks (
    id integer NOT NULL,
    code character varying(255),
    name character varying(255),
    dxcc character varying(255),
    region character varying(255),
    notes character varying(255),
    napalis_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    location public.geometry(Point,4326)
);


ALTER TABLE public.wwff_parks OWNER TO route_guides_production;

--
-- Name: wwff_parks_id_seq; Type: SEQUENCE; Schema: public; Owner: route_guides_production
--

CREATE SEQUENCE public.wwff_parks_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.wwff_parks_id_seq OWNER TO route_guides_production;

--
-- Name: wwff_parks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: route_guides_production
--

ALTER SEQUENCE public.wwff_parks_id_seq OWNED BY public.wwff_parks.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.admin_settings ALTER COLUMN id SET DEFAULT nextval('public.admin_settings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.ak_maps ALTER COLUMN id SET DEFAULT nextval('public.ak_maps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.asset_links ALTER COLUMN id SET DEFAULT nextval('public.asset_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.asset_photo_links ALTER COLUMN id SET DEFAULT nextval('public.asset_photo_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.asset_types ALTER COLUMN id SET DEFAULT nextval('public.asset_types_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.asset_web_links ALTER COLUMN id SET DEFAULT nextval('public.asset_web_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.assets ALTER COLUMN id SET DEFAULT nextval('public.assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.award_thresholds ALTER COLUMN id SET DEFAULT nextval('public.award_thresholds_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.award_user_links ALTER COLUMN id SET DEFAULT nextval('public.award_user_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.awards ALTER COLUMN id SET DEFAULT nextval('public.awards_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.bands ALTER COLUMN id SET DEFAULT nextval('public.bands_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.consolidated_spots ALTER COLUMN id SET DEFAULT nextval('public.consolidated_spots_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.continents ALTER COLUMN id SET DEFAULT nextval('public.continents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.crownparks ALTER COLUMN id SET DEFAULT nextval('public.docparks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.districts ALTER COLUMN id SET DEFAULT nextval('public.districts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.doc_tracks ALTER COLUMN id SET DEFAULT nextval('public.doc_tracks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.dxcc_prefixes ALTER COLUMN id SET DEFAULT nextval('public.dxcc_prefixes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.email_blacklists ALTER COLUMN id SET DEFAULT nextval('public.email_blacklists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.external_activations ALTER COLUMN id SET DEFAULT nextval('public.external_activations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.external_alerts ALTER COLUMN id SET DEFAULT nextval('public.external_alerts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.external_chases ALTER COLUMN id SET DEFAULT nextval('public.external_chases_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.external_spots ALTER COLUMN id SET DEFAULT nextval('public.external_spots_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.geological_eons ALTER COLUMN id SET DEFAULT nextval('public.geological_eons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.geological_epoches ALTER COLUMN id SET DEFAULT nextval('public.geological_epoches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.geological_eras ALTER COLUMN id SET DEFAULT nextval('public.geological_eras_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.geological_periods ALTER COLUMN id SET DEFAULT nextval('public.geological_periods_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.humps ALTER COLUMN id SET DEFAULT nextval('public.humps_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.huts ALTER COLUMN id SET DEFAULT nextval('public.huts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.images ALTER COLUMN id SET DEFAULT nextval('public.images_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.island_polygons ALTER COLUMN id SET DEFAULT nextval('public.island_polygons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.islands ALTER COLUMN id SET DEFAULT nextval('public.islands_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.legal_roads ALTER COLUMN id SET DEFAULT nextval('public.legal_roads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.lighthouses ALTER COLUMN id SET DEFAULT nextval('public.lighthouses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.logs ALTER COLUMN id SET DEFAULT nextval('public.logs_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.maplayers ALTER COLUMN id SET DEFAULT nextval('public.maplayers_id_seq'::regclass);


--
-- Name: ogc_fid; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.nz_tribal_lands ALTER COLUMN ogc_fid SET DEFAULT nextval('public.nz_tribal_lands_ogc_fid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.parks ALTER COLUMN id SET DEFAULT nextval('public.parks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.pota_parks ALTER COLUMN id SET DEFAULT nextval('public.pota_parks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.projections ALTER COLUMN id SET DEFAULT nextval('public.projections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.ratings ALTER COLUMN id SET DEFAULT nextval('public.ratings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.regions ALTER COLUMN id SET DEFAULT nextval('public.regions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.roads ALTER COLUMN id SET DEFAULT nextval('public.roads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.sessions ALTER COLUMN id SET DEFAULT nextval('public.sessions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.sota_peaks ALTER COLUMN id SET DEFAULT nextval('public.sota_peaks_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.sota_regions ALTER COLUMN id SET DEFAULT nextval('public.sota_regions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.states ALTER COLUMN id SET DEFAULT nextval('public.states_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.timezones ALTER COLUMN id SET DEFAULT nextval('public.timezones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.topics ALTER COLUMN id SET DEFAULT nextval('public.topics_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.uploads ALTER COLUMN id SET DEFAULT nextval('public.uploads_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.user_agents ALTER COLUMN id SET DEFAULT nextval('public.user_agents_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.user_callsigns ALTER COLUMN id SET DEFAULT nextval('public.user_callsigns_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.user_tokens ALTER COLUMN id SET DEFAULT nextval('public.user_tokens_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.user_topic_links ALTER COLUMN id SET DEFAULT nextval('public.user_topic_links_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.vk_assets ALTER COLUMN id SET DEFAULT nextval('public.vk_assets_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.vk_lakes ALTER COLUMN id SET DEFAULT nextval('public.vk_lakes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.volcanic_fields ALTER COLUMN id SET DEFAULT nextval('public.volcanic_fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.volcanos ALTER COLUMN id SET DEFAULT nextval('public.volcanos_id_seq'::regclass);


--
-- Name: gid; Type: DEFAULT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.volcanos_raw ALTER COLUMN gid SET DEFAULT nextval('public.volcanos_raw_gid_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.web_link_classes ALTER COLUMN id SET DEFAULT nextval('public.web_link_classes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.wishlists ALTER COLUMN id SET DEFAULT nextval('public.wishlists_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.wwff_parks ALTER COLUMN id SET DEFAULT nextval('public.wwff_parks_id_seq'::regclass);


--
-- Name: admin_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.admin_settings
    ADD CONSTRAINT admin_settings_pkey PRIMARY KEY (id);


--
-- Name: ak_maps_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.ak_maps
    ADD CONSTRAINT ak_maps_pkey PRIMARY KEY (id);


--
-- Name: asset_links_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.asset_links
    ADD CONSTRAINT asset_links_pkey PRIMARY KEY (id);


--
-- Name: asset_photo_links_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.asset_photo_links
    ADD CONSTRAINT asset_photo_links_pkey PRIMARY KEY (id);


--
-- Name: asset_types_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.asset_types
    ADD CONSTRAINT asset_types_pkey PRIMARY KEY (id);


--
-- Name: asset_web_links_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.asset_web_links
    ADD CONSTRAINT asset_web_links_pkey PRIMARY KEY (id);


--
-- Name: assets_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: award_thresholds_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.award_thresholds
    ADD CONSTRAINT award_thresholds_pkey PRIMARY KEY (id);


--
-- Name: award_user_links_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.award_user_links
    ADD CONSTRAINT award_user_links_pkey PRIMARY KEY (id);


--
-- Name: awards_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.awards
    ADD CONSTRAINT awards_pkey PRIMARY KEY (id);


--
-- Name: bands_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.bands
    ADD CONSTRAINT bands_pkey PRIMARY KEY (id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: consolidated_spots_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.consolidated_spots
    ADD CONSTRAINT consolidated_spots_pkey PRIMARY KEY (id);


--
-- Name: contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: continents_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.continents
    ADD CONSTRAINT continents_pkey PRIMARY KEY (id);


--
-- Name: districts_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- Name: doc_tracks_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.doc_tracks
    ADD CONSTRAINT doc_tracks_pkey PRIMARY KEY (id);


--
-- Name: docparks_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.crownparks
    ADD CONSTRAINT docparks_pkey PRIMARY KEY (id);


--
-- Name: dxcc_prefixes_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.dxcc_prefixes
    ADD CONSTRAINT dxcc_prefixes_pkey PRIMARY KEY (id);


--
-- Name: email_blacklists_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.email_blacklists
    ADD CONSTRAINT email_blacklists_pkey PRIMARY KEY (id);


--
-- Name: external_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.external_alerts
    ADD CONSTRAINT external_alerts_pkey PRIMARY KEY (id);


--
-- Name: external_spots_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.external_spots
    ADD CONSTRAINT external_spots_pkey PRIMARY KEY (id);


--
-- Name: geological_eons_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.geological_eons
    ADD CONSTRAINT geological_eons_pkey PRIMARY KEY (id);


--
-- Name: geological_epoches_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.geological_epoches
    ADD CONSTRAINT geological_epoches_pkey PRIMARY KEY (id);


--
-- Name: geological_eras_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.geological_eras
    ADD CONSTRAINT geological_eras_pkey PRIMARY KEY (id);


--
-- Name: geological_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.geological_periods
    ADD CONSTRAINT geological_periods_pkey PRIMARY KEY (id);


--
-- Name: humps_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.humps
    ADD CONSTRAINT humps_pkey PRIMARY KEY (id);


--
-- Name: huts_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.huts
    ADD CONSTRAINT huts_pkey PRIMARY KEY (id);


--
-- Name: images_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- Name: island_polygons_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.island_polygons
    ADD CONSTRAINT island_polygons_pkey PRIMARY KEY (id);


--
-- Name: islands_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.islands
    ADD CONSTRAINT islands_pkey PRIMARY KEY (id);


--
-- Name: items_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: legal_roads_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.legal_roads
    ADD CONSTRAINT legal_roads_pkey PRIMARY KEY (id);


--
-- Name: lighthouses_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.lighthouses
    ADD CONSTRAINT lighthouses_pkey PRIMARY KEY (id);


--
-- Name: logs_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: maplayers_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.maplayers
    ADD CONSTRAINT maplayers_pkey PRIMARY KEY (id);


--
-- Name: nz_tribal_lands_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.nz_tribal_lands
    ADD CONSTRAINT nz_tribal_lands_pkey PRIMARY KEY (ogc_fid);


--
-- Name: parks_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.parks
    ADD CONSTRAINT parks_pkey PRIMARY KEY (id);


--
-- Name: posts_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: pota_parks_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.pota_parks
    ADD CONSTRAINT pota_parks_pkey PRIMARY KEY (id);


--
-- Name: projections_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.projections
    ADD CONSTRAINT projections_pkey PRIMARY KEY (id);


--
-- Name: ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_pkey PRIMARY KEY (id);


--
-- Name: regions_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- Name: roads_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.roads
    ADD CONSTRAINT roads_pkey PRIMARY KEY (id);


--
-- Name: sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sota_activations_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.external_activations
    ADD CONSTRAINT sota_activations_pkey PRIMARY KEY (id);


--
-- Name: sota_chases_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.external_chases
    ADD CONSTRAINT sota_chases_pkey PRIMARY KEY (id);


--
-- Name: sota_peaks_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.sota_peaks
    ADD CONSTRAINT sota_peaks_pkey PRIMARY KEY (id);


--
-- Name: sota_regions_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.sota_regions
    ADD CONSTRAINT sota_regions_pkey PRIMARY KEY (id);


--
-- Name: states_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_pkey PRIMARY KEY (id);


--
-- Name: timezones_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.timezones
    ADD CONSTRAINT timezones_pkey PRIMARY KEY (id);


--
-- Name: topics_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT topics_pkey PRIMARY KEY (id);


--
-- Name: uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.uploads
    ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);


--
-- Name: user_agents_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.user_agents
    ADD CONSTRAINT user_agents_pkey PRIMARY KEY (id);


--
-- Name: user_callsigns_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.user_callsigns
    ADD CONSTRAINT user_callsigns_pkey PRIMARY KEY (id);


--
-- Name: user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: user_topic_links_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.user_topic_links
    ADD CONSTRAINT user_topic_links_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vk_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.vk_assets
    ADD CONSTRAINT vk_assets_pkey PRIMARY KEY (id);


--
-- Name: vk_lakes_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.vk_lakes
    ADD CONSTRAINT vk_lakes_pkey PRIMARY KEY (id);


--
-- Name: volcanic_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.volcanic_fields
    ADD CONSTRAINT volcanic_fields_pkey PRIMARY KEY (id);


--
-- Name: volcanos_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.volcanos
    ADD CONSTRAINT volcanos_pkey PRIMARY KEY (id);


--
-- Name: volcanos_raw_pkey; Type: CONSTRAINT; Schema: public; Owner: mbriggs
--

ALTER TABLE ONLY public.volcanos_raw
    ADD CONSTRAINT volcanos_raw_pkey PRIMARY KEY (gid);


--
-- Name: web_link_classes_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.web_link_classes
    ADD CONSTRAINT web_link_classes_pkey PRIMARY KEY (id);


--
-- Name: wishlists_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.wishlists
    ADD CONSTRAINT wishlists_pkey PRIMARY KEY (id);


--
-- Name: wwff_parks_pkey; Type: CONSTRAINT; Schema: public; Owner: route_guides_production
--

ALTER TABLE ONLY public.wwff_parks
    ADD CONSTRAINT wwff_parks_pkey PRIMARY KEY (id);


--
-- Name: assets_boundary_index; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX assets_boundary_index ON public.assets USING gist (boundary);


--
-- Name: assets_boundary_quite_simplified_index; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX assets_boundary_quite_simplified_index ON public.assets USING gist (boundary_quite_simplified);


--
-- Name: assets_boundary_simplified_index; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX assets_boundary_simplified_index ON public.assets USING gist (boundary_simplified);


--
-- Name: assets_boundary_very_simplified_index; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX assets_boundary_very_simplified_index ON public.assets USING gist (boundary_very_simplified);


--
-- Name: assets_location_index; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX assets_location_index ON public.assets USING gist (location);


--
-- Name: contacts_log_id_idx; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX contacts_log_id_idx ON public.contacts USING btree (log_id);


--
-- Name: contacts_user1id_idx; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX contacts_user1id_idx ON public.contacts USING btree (user1_id);


--
-- Name: contacts_user2id_idx; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX contacts_user2id_idx ON public.contacts USING btree (user2_id);


--
-- Name: districts_district_code_idx; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX districts_district_code_idx ON public.districts USING btree (district_code);


--
-- Name: districts_region_code_idx; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX districts_region_code_idx ON public.districts USING btree (region_code);


--
-- Name: docparks_wkt_index; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX docparks_wkt_index ON public.crownparks USING gist ("WKT");


--
-- Name: eas_asset_type_idx; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX eas_asset_type_idx ON public.external_activations USING btree (asset_type);


--
-- Name: eas_qso_count_idx; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX eas_qso_count_idx ON public.external_activations USING btree (qso_count);


--
-- Name: eas_userid_idx; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX eas_userid_idx ON public.external_activations USING btree (user_id);


--
-- Name: idx_assets_boundary; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX idx_assets_boundary ON public.assets USING gist (boundary);


--
-- Name: idx_assets_coalesced_geo; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX idx_assets_coalesced_geo ON public.assets USING gist ((COALESCE(az_boundary, boundary, location)));


--
-- Name: idx_assets_quite_simplified_3857; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX idx_assets_quite_simplified_3857 ON public.assets USING gist (public.st_transform(boundary_quite_simplified, 3857));


--
-- Name: idx_assets_type_and_spatial; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX idx_assets_type_and_spatial ON public.assets USING gist (asset_type, (COALESCE(boundary, location)));


--
-- Name: idx_assets_uppdated_at; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX idx_assets_uppdated_at ON public.assets USING btree (updated_at);


--
-- Name: idx_contacts_asset1_classes; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX idx_contacts_asset1_classes ON public.contacts USING gin (asset1_classes);


--
-- Name: idx_contacts_asset1_codes_gin; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX idx_contacts_asset1_codes_gin ON public.contacts USING gin (asset1_codes);


--
-- Name: idx_contacts_asset2_classes; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX idx_contacts_asset2_classes ON public.contacts USING gin (asset2_classes);


--
-- Name: idx_contacts_asset2_codes_gin; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX idx_contacts_asset2_codes_gin ON public.contacts USING gin (asset2_codes);


--
-- Name: idx_contacts_date_time; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX idx_contacts_date_time ON public.contacts USING btree (date, "time");


--
-- Name: idx_cs_updated_at; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX idx_cs_updated_at ON public.consolidated_spots USING btree (updated_at);


--
-- Name: idx_external_spots_time_activator; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX idx_external_spots_time_activator ON public.external_spots USING btree ("time", "activatorCallsign");


--
-- Name: idx_logs_asset_classes; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX idx_logs_asset_classes ON public.logs USING gin (asset_classes);


--
-- Name: idx_logs_asset_codes_gin; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX idx_logs_asset_codes_gin ON public.logs USING gin (asset_codes);


--
-- Name: idx_logs_callsign1_id; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX idx_logs_callsign1_id ON public.logs USING btree (callsign1, id);


--
-- Name: idx_nz_tribal_lands_quite_simplified_3857; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX idx_nz_tribal_lands_quite_simplified_3857 ON public.nz_tribal_lands USING gist (public.st_transform(boundary_quite_simplified, 3857));


--
-- Name: idx_tribal_lands_boundary_quite_simplified; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX idx_tribal_lands_boundary_quite_simplified ON public.nz_tribal_lands USING gist (boundary_quite_simplified);


--
-- Name: idx_tribal_lands_geom_3857; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX idx_tribal_lands_geom_3857 ON public.nz_tribal_lands USING gist (public.st_transform(wkb_geometry, 3857));


--
-- Name: idx_user_callsigns_lookup; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX idx_user_callsigns_lookup ON public.user_callsigns USING btree (callsign, from_date, to_date);


--
-- Name: index_asset_links_on_contained_code; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_asset_links_on_contained_code ON public.asset_links USING btree (contained_code);


--
-- Name: index_asset_links_on_containing_code; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_asset_links_on_containing_code ON public.asset_links USING btree (containing_code);


--
-- Name: index_asset_types_on_name; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_asset_types_on_name ON public.asset_types USING btree (name);


--
-- Name: index_assets_on_asset_type; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_assets_on_asset_type ON public.assets USING btree (asset_type);


--
-- Name: index_assets_on_asset_type_and_updated_at; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_assets_on_asset_type_and_updated_at ON public.assets USING btree (asset_type, updated_at);


--
-- Name: index_assets_on_code; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_assets_on_code ON public.assets USING btree (code);


--
-- Name: index_assets_on_safecode; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_assets_on_safecode ON public.assets USING btree (safecode);


--
-- Name: index_contacts_on_callsign1; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX index_contacts_on_callsign1 ON public.contacts USING btree (callsign1);


--
-- Name: index_contacts_on_callsign2; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX index_contacts_on_callsign2 ON public.contacts USING btree (callsign2);


--
-- Name: index_contacts_on_date; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX index_contacts_on_date ON public.contacts USING btree (date);


--
-- Name: index_logs_on_date; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_logs_on_date ON public.logs USING btree (date);


--
-- Name: index_name; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_name ON public.assets USING btree (old_code);


--
-- Name: index_ratings_on_asset_code; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_ratings_on_asset_code ON public.ratings USING btree (asset_code);


--
-- Name: index_ratings_on_user_id; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_ratings_on_user_id ON public.ratings USING btree (user_id);


--
-- Name: index_sessions_on_session_id; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE UNIQUE INDEX index_sessions_on_session_id ON public.sessions USING btree (session_id);


--
-- Name: index_sessions_on_updated_at; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_sessions_on_updated_at ON public.sessions USING btree (updated_at);


--
-- Name: index_user_agents_on_user_ip; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_user_agents_on_user_ip ON public.user_agents USING btree (user_ip);


--
-- Name: index_users_on_callsign; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX index_users_on_callsign ON public.users USING btree (callsign);


--
-- Name: index_users_on_remember_token; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX index_users_on_remember_token ON public.users USING btree (remember_token);


--
-- Name: index_wishlists_on_asset_code; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_wishlists_on_asset_code ON public.wishlists USING btree (asset_code);


--
-- Name: index_wishlists_on_user_id; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX index_wishlists_on_user_id ON public.wishlists USING btree (user_id);


--
-- Name: logs_user1id_idx; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX logs_user1id_idx ON public.logs USING btree (user1_id);


--
-- Name: nz_tribal_lands_wkb_geometry_geom_idx; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE INDEX nz_tribal_lands_wkb_geometry_geom_idx ON public.nz_tribal_lands USING gist (wkb_geometry);


--
-- Name: regions_sota_code_idx; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX regions_sota_code_idx ON public.regions USING btree (sota_code);


--
-- Name: states_geom_idx; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX states_geom_idx ON public.states USING gist (boundary);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: mbriggs
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- Name: vk_award_indx; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX vk_award_indx ON public.vk_assets USING btree (award);


--
-- Name: vk_code_indx; Type: INDEX; Schema: public; Owner: route_guides_production
--

CREATE INDEX vk_code_indx ON public.vk_assets USING btree (code);


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

