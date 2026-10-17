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
-- Name: btree_gist; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: postgres_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: st_cardinaldirection(double precision); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.st_cardinaldirection(azimuth double precision) RETURNS character varying
    LANGUAGE plpgsql IMMUTABLE STRICT
    AS $$
BEGIN
  -- Guard against null or missing inputs gracefully
  IF azimuth IS NULL THEN
    RETURN NULL;
  END IF;

  -- Group azimuth degrees into standard 45-degree compass vectors
  RETURN CASE
    WHEN azimuth >= 337.5 OR azimuth < 22.5  THEN 'N'
    WHEN azimuth >= 22.5  AND azimuth < 67.5  THEN 'NE'
    WHEN azimuth >= 67.5  AND azimuth < 112.5 THEN 'E'
    WHEN azimuth >= 112.5 AND azimuth < 157.5 THEN 'SE'
    WHEN azimuth >= 157.5 AND azimuth < 202.5 THEN 'S'
    WHEN azimuth >= 202.5 AND azimuth < 247.5 THEN 'SW'
    WHEN azimuth >= 247.5 AND azimuth < 292.5 THEN 'W'
    WHEN azimuth >= 292.5 AND azimuth < 337.5 THEN 'NW'
    ELSE 'N'
  END;
END;
$$;


--
-- Name: utmzone(public.geometry); Type: FUNCTION; Schema: public; Owner: -
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


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: admin_settings; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: admin_settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.admin_settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.admin_settings_id_seq OWNED BY public.admin_settings.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: asset_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_links (
    id integer NOT NULL,
    contained_code character varying(255),
    containing_code character varying(255),
    overlap double precision
);


--
-- Name: asset_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asset_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asset_links_id_seq OWNED BY public.asset_links.id;


--
-- Name: asset_photo_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_photo_links (
    id integer NOT NULL,
    asset_code character varying(255),
    link_url character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    photo_id integer
);


--
-- Name: asset_photo_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asset_photo_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_photo_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asset_photo_links_id_seq OWNED BY public.asset_photo_links.id;


--
-- Name: asset_types; Type: TABLE; Schema: public; Owner: -
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
    like_pattern character varying(255),
    allow_multi boolean
);


--
-- Name: asset_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asset_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asset_types_id_seq OWNED BY public.asset_types.id;


--
-- Name: asset_web_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.asset_web_links (
    id integer NOT NULL,
    asset_code character varying(255),
    url character varying(255),
    link_class character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: asset_web_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.asset_web_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: asset_web_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.asset_web_links_id_seq OWNED BY public.asset_web_links.id;


--
-- Name: assets; Type: TABLE; Schema: public; Owner: -
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
    nearest_road_id character varying,
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
    access_vk_state_park_ids character varying(255)[] DEFAULT '{}'::character varying[],
    geom_id character varying,
    geom_source character varying,
    name_id character varying,
    name_source character varying
);


--
-- Name: assets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assets_id_seq OWNED BY public.assets.id;


--
-- Name: award_thresholds; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.award_thresholds (
    id integer NOT NULL,
    threshold integer,
    name character varying(255),
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: award_thresholds_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.award_thresholds_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: award_thresholds_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.award_thresholds_id_seq OWNED BY public.award_thresholds.id;


--
-- Name: award_user_links; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: award_user_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.award_user_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: award_user_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.award_user_links_id_seq OWNED BY public.award_user_links.id;


--
-- Name: awards; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: awards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.awards_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: awards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.awards_id_seq OWNED BY public.awards.id;


--
-- Name: bands; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bands (
    id integer NOT NULL,
    meter_band character varying(255),
    freq_band character varying(255),
    "group" character varying(255),
    min_frequency double precision,
    max_frequency double precision
);


--
-- Name: bands_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bands_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bands_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bands_id_seq OWNED BY public.bands.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    id integer NOT NULL,
    comment text,
    code character varying(255),
    updated_by_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: contacts; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contacts_id_seq OWNED BY public.contacts.id;


--
-- Name: continents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.continents (
    id integer NOT NULL,
    name character varying(255),
    code character varying(255)
);


--
-- Name: continents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.continents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: continents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.continents_id_seq OWNED BY public.continents.id;


--
-- Name: districts; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.districts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.districts_id_seq OWNED BY public.districts.id;


--
-- Name: dxcc_prefixes; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: dxcc_prefixes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.dxcc_prefixes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dxcc_prefixes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.dxcc_prefixes_id_seq OWNED BY public.dxcc_prefixes.id;


--
-- Name: email_blacklists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.email_blacklists (
    id integer NOT NULL,
    email_provider character varying(255)
);


--
-- Name: email_blacklists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.email_blacklists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_blacklists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.email_blacklists_id_seq OWNED BY public.email_blacklists.id;


--
-- Name: geological_eons; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.geological_eons (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: geological_eons_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.geological_eons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: geological_eons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.geological_eons_id_seq OWNED BY public.geological_eons.id;


--
-- Name: geological_epoches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.geological_epoches (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: geological_epoches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.geological_epoches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: geological_epoches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.geological_epoches_id_seq OWNED BY public.geological_epoches.id;


--
-- Name: geological_eras; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.geological_eras (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: geological_eras_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.geological_eras_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: geological_eras_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.geological_eras_id_seq OWNED BY public.geological_eras.id;


--
-- Name: geological_periods; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.geological_periods (
    id integer NOT NULL,
    name character varying(255),
    start_mya double precision,
    end_mya double precision,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: geological_periods_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.geological_periods_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: geological_periods_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.geological_periods_id_seq OWNED BY public.geological_periods.id;


--
-- Name: images; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: images_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.images_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: images_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.images_id_seq OWNED BY public.images.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: logs; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.logs_id_seq OWNED BY public.logs.id;


--
-- Name: maplayers; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: maplayers_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.maplayers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maplayers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maplayers_id_seq OWNED BY public.maplayers.id;


--
-- Name: posts; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: posts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.posts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: posts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.posts_id_seq OWNED BY public.posts.id;


--
-- Name: projections; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: projections_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projections_id_seq OWNED BY public.projections.id;


--
-- Name: ratings; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: ratings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ratings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ratings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ratings_id_seq OWNED BY public.ratings.id;


--
-- Name: regions; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: regions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regions_id_seq OWNED BY public.regions.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: states; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: states_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.states_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: states_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.states_id_seq OWNED BY public.states.id;


--
-- Name: timezones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.timezones (
    id integer NOT NULL,
    name character varying(255),
    description character varying(255),
    difference integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: timezones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.timezones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: timezones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.timezones_id_seq OWNED BY public.timezones.id;


--
-- Name: topics; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: topics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.topics_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: topics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.topics_id_seq OWNED BY public.topics.id;


--
-- Name: uploads; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: uploads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.uploads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: uploads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.uploads_id_seq OWNED BY public.uploads.id;


--
-- Name: user_callsigns; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: user_callsigns_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_callsigns_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_callsigns_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_callsigns_id_seq OWNED BY public.user_callsigns.id;


--
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_tokens (
    id integer NOT NULL,
    remember_token character varying(255),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: user_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_tokens_id_seq OWNED BY public.user_tokens.id;


--
-- Name: user_topic_links; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: user_topic_links_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_topic_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_topic_links_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_topic_links_id_seq OWNED BY public.user_topic_links.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: volcanic_fields; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: volcanic_fields_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.volcanic_fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: volcanic_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.volcanic_fields_id_seq OWNED BY public.volcanic_fields.id;


--
-- Name: web_link_classes; Type: TABLE; Schema: public; Owner: -
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


--
-- Name: web_link_classes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.web_link_classes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: web_link_classes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.web_link_classes_id_seq OWNED BY public.web_link_classes.id;


--
-- Name: wishlists; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wishlists (
    id integer NOT NULL,
    asset_code character varying(255),
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone
);


--
-- Name: wishlists_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wishlists_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wishlists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wishlists_id_seq OWNED BY public.wishlists.id;


--
-- Name: admin_settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_settings ALTER COLUMN id SET DEFAULT nextval('public.admin_settings_id_seq'::regclass);


--
-- Name: asset_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_links ALTER COLUMN id SET DEFAULT nextval('public.asset_links_id_seq'::regclass);


--
-- Name: asset_photo_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_photo_links ALTER COLUMN id SET DEFAULT nextval('public.asset_photo_links_id_seq'::regclass);


--
-- Name: asset_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_types ALTER COLUMN id SET DEFAULT nextval('public.asset_types_id_seq'::regclass);


--
-- Name: asset_web_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_web_links ALTER COLUMN id SET DEFAULT nextval('public.asset_web_links_id_seq'::regclass);


--
-- Name: assets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets ALTER COLUMN id SET DEFAULT nextval('public.assets_id_seq'::regclass);


--
-- Name: award_thresholds id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.award_thresholds ALTER COLUMN id SET DEFAULT nextval('public.award_thresholds_id_seq'::regclass);


--
-- Name: award_user_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.award_user_links ALTER COLUMN id SET DEFAULT nextval('public.award_user_links_id_seq'::regclass);


--
-- Name: awards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awards ALTER COLUMN id SET DEFAULT nextval('public.awards_id_seq'::regclass);


--
-- Name: bands id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bands ALTER COLUMN id SET DEFAULT nextval('public.bands_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: contacts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts ALTER COLUMN id SET DEFAULT nextval('public.contacts_id_seq'::regclass);


--
-- Name: continents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.continents ALTER COLUMN id SET DEFAULT nextval('public.continents_id_seq'::regclass);


--
-- Name: districts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts ALTER COLUMN id SET DEFAULT nextval('public.districts_id_seq'::regclass);


--
-- Name: dxcc_prefixes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dxcc_prefixes ALTER COLUMN id SET DEFAULT nextval('public.dxcc_prefixes_id_seq'::regclass);


--
-- Name: email_blacklists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_blacklists ALTER COLUMN id SET DEFAULT nextval('public.email_blacklists_id_seq'::regclass);


--
-- Name: geological_eons id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geological_eons ALTER COLUMN id SET DEFAULT nextval('public.geological_eons_id_seq'::regclass);


--
-- Name: geological_epoches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geological_epoches ALTER COLUMN id SET DEFAULT nextval('public.geological_epoches_id_seq'::regclass);


--
-- Name: geological_eras id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geological_eras ALTER COLUMN id SET DEFAULT nextval('public.geological_eras_id_seq'::regclass);


--
-- Name: geological_periods id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geological_periods ALTER COLUMN id SET DEFAULT nextval('public.geological_periods_id_seq'::regclass);


--
-- Name: images id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.images ALTER COLUMN id SET DEFAULT nextval('public.images_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs ALTER COLUMN id SET DEFAULT nextval('public.logs_id_seq'::regclass);


--
-- Name: maplayers id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maplayers ALTER COLUMN id SET DEFAULT nextval('public.maplayers_id_seq'::regclass);


--
-- Name: posts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts ALTER COLUMN id SET DEFAULT nextval('public.posts_id_seq'::regclass);


--
-- Name: projections id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projections ALTER COLUMN id SET DEFAULT nextval('public.projections_id_seq'::regclass);


--
-- Name: ratings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings ALTER COLUMN id SET DEFAULT nextval('public.ratings_id_seq'::regclass);


--
-- Name: regions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions ALTER COLUMN id SET DEFAULT nextval('public.regions_id_seq'::regclass);


--
-- Name: states id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states ALTER COLUMN id SET DEFAULT nextval('public.states_id_seq'::regclass);


--
-- Name: timezones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timezones ALTER COLUMN id SET DEFAULT nextval('public.timezones_id_seq'::regclass);


--
-- Name: topics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topics ALTER COLUMN id SET DEFAULT nextval('public.topics_id_seq'::regclass);


--
-- Name: uploads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uploads ALTER COLUMN id SET DEFAULT nextval('public.uploads_id_seq'::regclass);


--
-- Name: user_callsigns id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_callsigns ALTER COLUMN id SET DEFAULT nextval('public.user_callsigns_id_seq'::regclass);


--
-- Name: user_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tokens ALTER COLUMN id SET DEFAULT nextval('public.user_tokens_id_seq'::regclass);


--
-- Name: user_topic_links id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_topic_links ALTER COLUMN id SET DEFAULT nextval('public.user_topic_links_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: volcanic_fields id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.volcanic_fields ALTER COLUMN id SET DEFAULT nextval('public.volcanic_fields_id_seq'::regclass);


--
-- Name: web_link_classes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_link_classes ALTER COLUMN id SET DEFAULT nextval('public.web_link_classes_id_seq'::regclass);


--
-- Name: wishlists id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wishlists ALTER COLUMN id SET DEFAULT nextval('public.wishlists_id_seq'::regclass);


--
-- Name: admin_settings admin_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_settings
    ADD CONSTRAINT admin_settings_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: asset_links asset_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_links
    ADD CONSTRAINT asset_links_pkey PRIMARY KEY (id);


--
-- Name: asset_photo_links asset_photo_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_photo_links
    ADD CONSTRAINT asset_photo_links_pkey PRIMARY KEY (id);


--
-- Name: asset_types asset_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_types
    ADD CONSTRAINT asset_types_pkey PRIMARY KEY (id);


--
-- Name: asset_web_links asset_web_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.asset_web_links
    ADD CONSTRAINT asset_web_links_pkey PRIMARY KEY (id);


--
-- Name: assets assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assets
    ADD CONSTRAINT assets_pkey PRIMARY KEY (id);


--
-- Name: award_thresholds award_thresholds_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.award_thresholds
    ADD CONSTRAINT award_thresholds_pkey PRIMARY KEY (id);


--
-- Name: award_user_links award_user_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.award_user_links
    ADD CONSTRAINT award_user_links_pkey PRIMARY KEY (id);


--
-- Name: awards awards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.awards
    ADD CONSTRAINT awards_pkey PRIMARY KEY (id);


--
-- Name: bands bands_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bands
    ADD CONSTRAINT bands_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: contacts contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contacts
    ADD CONSTRAINT contacts_pkey PRIMARY KEY (id);


--
-- Name: continents continents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.continents
    ADD CONSTRAINT continents_pkey PRIMARY KEY (id);


--
-- Name: districts districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- Name: dxcc_prefixes dxcc_prefixes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.dxcc_prefixes
    ADD CONSTRAINT dxcc_prefixes_pkey PRIMARY KEY (id);


--
-- Name: email_blacklists email_blacklists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.email_blacklists
    ADD CONSTRAINT email_blacklists_pkey PRIMARY KEY (id);


--
-- Name: geological_eons geological_eons_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geological_eons
    ADD CONSTRAINT geological_eons_pkey PRIMARY KEY (id);


--
-- Name: geological_epoches geological_epoches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geological_epoches
    ADD CONSTRAINT geological_epoches_pkey PRIMARY KEY (id);


--
-- Name: geological_eras geological_eras_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geological_eras
    ADD CONSTRAINT geological_eras_pkey PRIMARY KEY (id);


--
-- Name: geological_periods geological_periods_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.geological_periods
    ADD CONSTRAINT geological_periods_pkey PRIMARY KEY (id);


--
-- Name: images images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.images
    ADD CONSTRAINT images_pkey PRIMARY KEY (id);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: logs logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.logs
    ADD CONSTRAINT logs_pkey PRIMARY KEY (id);


--
-- Name: maplayers maplayers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maplayers
    ADD CONSTRAINT maplayers_pkey PRIMARY KEY (id);


--
-- Name: posts posts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.posts
    ADD CONSTRAINT posts_pkey PRIMARY KEY (id);


--
-- Name: projections projections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projections
    ADD CONSTRAINT projections_pkey PRIMARY KEY (id);


--
-- Name: ratings ratings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ratings
    ADD CONSTRAINT ratings_pkey PRIMARY KEY (id);


--
-- Name: regions regions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regions
    ADD CONSTRAINT regions_pkey PRIMARY KEY (id);


--
-- Name: states states_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.states
    ADD CONSTRAINT states_pkey PRIMARY KEY (id);


--
-- Name: timezones timezones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timezones
    ADD CONSTRAINT timezones_pkey PRIMARY KEY (id);


--
-- Name: topics topics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.topics
    ADD CONSTRAINT topics_pkey PRIMARY KEY (id);


--
-- Name: uploads uploads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.uploads
    ADD CONSTRAINT uploads_pkey PRIMARY KEY (id);


--
-- Name: user_callsigns user_callsigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_callsigns
    ADD CONSTRAINT user_callsigns_pkey PRIMARY KEY (id);


--
-- Name: user_tokens user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: user_topic_links user_topic_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_topic_links
    ADD CONSTRAINT user_topic_links_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: volcanic_fields volcanic_fields_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.volcanic_fields
    ADD CONSTRAINT volcanic_fields_pkey PRIMARY KEY (id);


--
-- Name: web_link_classes web_link_classes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.web_link_classes
    ADD CONSTRAINT web_link_classes_pkey PRIMARY KEY (id);


--
-- Name: wishlists wishlists_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wishlists
    ADD CONSTRAINT wishlists_pkey PRIMARY KEY (id);


--
-- Name: assets_boundary_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_boundary_index ON public.assets USING gist (boundary);


--
-- Name: assets_boundary_quite_simplified_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_boundary_quite_simplified_index ON public.assets USING gist (boundary_quite_simplified);


--
-- Name: assets_boundary_simplified_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_boundary_simplified_index ON public.assets USING gist (boundary_simplified);


--
-- Name: assets_boundary_very_simplified_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_boundary_very_simplified_index ON public.assets USING gist (boundary_very_simplified);


--
-- Name: assets_location_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX assets_location_index ON public.assets USING gist (location);


--
-- Name: contacts_log_id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contacts_log_id_idx ON public.contacts USING btree (log_id);


--
-- Name: contacts_user1id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contacts_user1id_idx ON public.contacts USING btree (user1_id);


--
-- Name: contacts_user2id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX contacts_user2id_idx ON public.contacts USING btree (user2_id);


--
-- Name: districts_district_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX districts_district_code_idx ON public.districts USING btree (district_code);


--
-- Name: districts_region_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX districts_region_code_idx ON public.districts USING btree (region_code);


--
-- Name: idx_assets_boundary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_boundary ON public.assets USING gist (boundary);


--
-- Name: idx_assets_coalesced_geo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_coalesced_geo ON public.assets USING gist (COALESCE(az_boundary, boundary, location));


--
-- Name: idx_assets_quite_simplified_3857; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_quite_simplified_3857 ON public.assets USING gist (public.st_transform(boundary_quite_simplified, 3857));


--
-- Name: idx_assets_uppdated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_assets_uppdated_at ON public.assets USING btree (updated_at);


--
-- Name: idx_contacts_asset1_classes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contacts_asset1_classes ON public.contacts USING gin (asset1_classes);


--
-- Name: idx_contacts_asset1_codes_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contacts_asset1_codes_gin ON public.contacts USING gin (asset1_codes);


--
-- Name: idx_contacts_asset2_classes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contacts_asset2_classes ON public.contacts USING gin (asset2_classes);


--
-- Name: idx_contacts_asset2_codes_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contacts_asset2_codes_gin ON public.contacts USING gin (asset2_codes);


--
-- Name: idx_contacts_date_time; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_contacts_date_time ON public.contacts USING btree (date, "time");


--
-- Name: idx_logs_asset_classes; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_logs_asset_classes ON public.logs USING gin (asset_classes);


--
-- Name: idx_logs_asset_codes_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_logs_asset_codes_gin ON public.logs USING gin (asset_codes);


--
-- Name: idx_logs_callsign1_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_logs_callsign1_id ON public.logs USING btree (callsign1, id);


--
-- Name: idx_user_callsigns_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_callsigns_lookup ON public.user_callsigns USING btree (callsign, from_date, to_date);


--
-- Name: index_asset_links_on_contained_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_asset_links_on_contained_code ON public.asset_links USING btree (contained_code);


--
-- Name: index_asset_links_on_containing_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_asset_links_on_containing_code ON public.asset_links USING btree (containing_code);


--
-- Name: index_asset_types_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_asset_types_on_name ON public.asset_types USING btree (name);


--
-- Name: index_assets_on_asset_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_asset_type ON public.assets USING btree (asset_type);


--
-- Name: index_assets_on_asset_type_and_updated_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_asset_type_and_updated_at ON public.assets USING btree (asset_type, updated_at);


--
-- Name: index_assets_on_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_code ON public.assets USING btree (code);


--
-- Name: index_assets_on_safecode; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_assets_on_safecode ON public.assets USING btree (safecode);


--
-- Name: index_contacts_on_callsign1; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_callsign1 ON public.contacts USING btree (callsign1);


--
-- Name: index_contacts_on_callsign2; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_callsign2 ON public.contacts USING btree (callsign2);


--
-- Name: index_contacts_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_contacts_on_date ON public.contacts USING btree (date);


--
-- Name: index_logs_on_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_logs_on_date ON public.logs USING btree (date);


--
-- Name: index_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_name ON public.assets USING btree (old_code);


--
-- Name: index_ratings_on_asset_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ratings_on_asset_code ON public.ratings USING btree (asset_code);


--
-- Name: index_ratings_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_ratings_on_user_id ON public.ratings USING btree (user_id);


--
-- Name: index_users_on_callsign; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_callsign ON public.users USING btree (callsign);


--
-- Name: index_users_on_remember_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_remember_token ON public.users USING btree (remember_token);


--
-- Name: index_wishlists_on_asset_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wishlists_on_asset_code ON public.wishlists USING btree (asset_code);


--
-- Name: index_wishlists_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_wishlists_on_user_id ON public.wishlists USING btree (user_id);


--
-- Name: logs_user1id_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX logs_user1id_idx ON public.logs USING btree (user1_id);


--
-- Name: regions_sota_code_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX regions_sota_code_idx ON public.regions USING btree (sota_code);


--
-- Name: states_geom_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX states_geom_idx ON public.states USING gist (boundary);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20261016195337'),
('20261016002539'),
('20261009060443'),
('20261009045042'),
('20261008045434'),
('20261003003844'),
('20260927034145'),
('20260926211603'),
('20260919030816'),
('20260913084133'),
('20260816195403'),
('20260723041914'),
('20260714035748'),
('20260712002710'),
('20260711035057'),
('20260710212154'),
('20260709075917'),
('20260527003752'),
('20260519053618'),
('20260519052644'),
('20260426224343'),
('20260426224020'),
('20260415220504'),
('20260415204930'),
('20260415062141'),
('20260415001552'),
('20260414233843'),
('20260414230407'),
('20260412053236'),
('20260412041300'),
('20260409022344'),
('20260318003045'),
('20260318003032'),
('20260310035800'),
('20260201050445'),
('20260129180503'),
('20260119071140'),
('20260117032003'),
('20260116011658'),
('20260115045208'),
('20260115042846'),
('20260114025255'),
('20260110221025'),
('20260104201820'),
('20260104031252'),
('20251207025044'),
('20251202013926'),
('20250915040625'),
('20250910050052'),
('20250910044245'),
('20250831181243'),
('20250813052045'),
('20250805030920'),
('20250712084140'),
('20250711095801'),
('20250709174345'),
('20250627183501'),
('20250525182100'),
('20250308003311'),
('20250307213957'),
('20250218041707'),
('20250119003321'),
('20250118182321'),
('20241224005139'),
('20241212074237'),
('20241207063114'),
('20241204222740'),
('20241108050228'),
('20241108044550'),
('20241107222219'),
('20241027052530'),
('20240923094850'),
('20240923083710'),
('20240923081825'),
('20240923081817'),
('20240923081810'),
('20240923081753'),
('20240922073956'),
('20240922064219'),
('20240915012256'),
('20240914082040'),
('20240907082003'),
('20240906004152'),
('20240905193547'),
('20240905192516'),
('20240905012110'),
('20240901205857'),
('20240830042206'),
('20240827082640'),
('20240826195319'),
('20240814073508'),
('20240806031238'),
('20240624014224'),
('20240412000213'),
('20240313062951'),
('20231223033245'),
('20231220223845'),
('20231013231816'),
('20230930071202'),
('20230930024208'),
('20230915075218'),
('20230915073522'),
('20230915041527'),
('20230915035901'),
('20230915033636'),
('20230806232229'),
('20230412190834'),
('20230412084324'),
('20230411220133'),
('20230411220111'),
('20230409013714'),
('20221005234213'),
('20220921200441'),
('20220921200410'),
('20220819193405'),
('20220729192219'),
('20220729023851'),
('20220727223933'),
('20220727220355'),
('20220727220137'),
('20220727215405'),
('20220719000846'),
('20220718080335'),
('20220718012101'),
('20220709000030'),
('20220708235447'),
('20220708231905'),
('20220604020456'),
('20220531211049'),
('20220531193508'),
('20220427204541'),
('20220418025718'),
('20220417230815'),
('20220310215038'),
('20220310212452'),
('20220130035642'),
('20220130024738'),
('20220126230629'),
('20220105063153'),
('20211127084842'),
('20211116031656'),
('20210911193736'),
('20210713051123'),
('20210713050057'),
('20210707025114'),
('20210619010441'),
('20210619010430'),
('20210619010353'),
('20210619010341'),
('20210613055316'),
('20210608081049'),
('20210530214054'),
('20210530201820'),
('20210529200731'),
('20210528210841'),
('20210528205626'),
('20210528195045'),
('20210528014537'),
('20210525054106'),
('20210520020505'),
('20210519103427'),
('20210517094957'),
('20210517091614'),
('20210517083001'),
('20210515085623'),
('20210515054041'),
('20210515023626'),
('20210514014300'),
('20210513083703'),
('20210513073135'),
('20210512070724'),
('20210512065727'),
('20210512064513'),
('20210511081346'),
('20210508202649'),
('20210508194921'),
('20210508194757'),
('20210506082539'),
('20210506081703'),
('20210505102007'),
('20210504035121'),
('20210504034542'),
('20210502072738'),
('20210502071227'),
('20210501233759'),
('20210501052146'),
('20210501041446'),
('20210429052541'),
('20210427084300'),
('20210427080334'),
('20210427074318'),
('20210427070045'),
('20210427063919'),
('20210427063300'),
('20210421063657'),
('20210419041701'),
('20210418215155'),
('20210411010647'),
('20210410235326'),
('20210403051207'),
('20210402210958'),
('20210402204116'),
('20210402181815'),
('20210326201857'),
('20210320041626'),
('20210306071503'),
('20210305224752'),
('20201116012706'),
('20201010072518'),
('20200919081406'),
('20200919081353'),
('20200919063257'),
('20200919053206'),
('20200912030009'),
('20200912023620'),
('20200823031337'),
('20200809010013'),
('20200809010002'),
('20200808213903'),
('20200803092328'),
('20200802094050'),
('20200802083955'),
('20200802040524'),
('20200222033248'),
('20200222032121'),
('20200201070409'),
('20200118205103'),
('20200110205442'),
('20191229065621'),
('20191226221507'),
('20191226052520'),
('20191223040338'),
('20191214222953'),
('20191214060717'),
('20191214060654'),
('20191214060653'),
('20191210072958'),
('20191210065819');

