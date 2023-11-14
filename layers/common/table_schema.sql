CREATE EXTENSION IF NOT EXISTS HSTORE;
CREATE EXTENSION IF NOT EXISTS postgis;

DROP TABLE IF EXISTS osm_indoor_polygon CASCADE;
CREATE TABLE osm_indoor_polygon (
    id integer NOT NULL,
    osm_id bigint NOT NULL,
    class character varying,
    subclass character varying,
    level character varying,
    repeat_on character varying,
    ref character varying,
    name character varying,
    name_en character varying,
    name_de character varying,
    access character varying,
    tags hstore,
    geometry geometry(Geometry)
);

DROP TABLE IF EXISTS osm_indoor_linestring CASCADE;
CREATE TABLE osm_indoor_linestring (
    id integer NOT NULL,
    osm_id bigint NOT NULL,
    class character varying,
    level character varying,
    repeat_on character varying,
    geometry geometry(LineString)
);

CREATE TABLE osm_transportation_linestring (
    id integer NOT NULL,
    osm_id bigint NOT NULL,
    class character varying,
    conveying character varying,
    level character varying,
    repeat_on character varying,
    geometry geometry(LineString)
);

DROP TABLE IF EXISTS osm_poi_point CASCADE;
CREATE TABLE osm_poi_point (
    id integer NOT NULL,
    osm_id bigint NOT NULL,
    name character varying,
    name_en character varying,
    name_de character varying,
    ref character varying,
    tags hstore,
    subclass character varying,
    mapping_key character varying,
    station character varying,
    funicular character varying,
    information character varying,
    uic_ref character varying,
    religion character varying,
    level character varying,
    indoor boolean,
    layer integer,
    sport character varying,
    vending character varying,
    repeat_on character varying,
    geometry geometry(Geometry,3857)
);
DROP TABLE IF EXISTS osm_poi_polygon CASCADE;
CREATE TABLE osm_poi_polygon (
    id integer NOT NULL,
    osm_id bigint NOT NULL,
    name character varying,
    name_en character varying,
    name_de character varying,
    ref character varying,
    tags hstore,
    subclass character varying,
    mapping_key character varying,
    station character varying,
    funicular character varying,
    information character varying,
    uic_ref character varying,
    religion character varying,
    level character varying,
    indoor boolean,
    layer integer,
    sport character varying,
    vending character varying,
    repeat_on character varying,
    geometry geometry(Geometry,3857)
);
