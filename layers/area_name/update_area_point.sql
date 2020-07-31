DROP TRIGGER IF EXISTS trigger_flag_point ON osm_indoor_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON area_point.updates;

DROP MATERIALIZED VIEW IF EXISTS  osm_area_point CASCADE;

CREATE MATERIALIZED VIEW osm_area_point AS (
    SELECT
        wp.osm_id, ST_PointOnSurface(wp.geometry) AS geometry,
        wp.name, wp.name_en, wp.name_de,
        wp.level, wp.repeat_on
    FROM osm_indoor_polygon AS wp
    WHERE wp.name <> '' AND NOT is_poi(wp.tags)
);
CREATE INDEX IF NOT EXISTS osm_area_point_geometry_idx ON osm_area_point USING gist (geometry);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS area_point;

CREATE TABLE IF NOT EXISTS area_point.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION area_point.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO area_point.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION area_point.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh area_point';
    REFRESH MATERIALIZED VIEW osm_area_point;
    DELETE FROM area_point.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag_point
    AFTER INSERT OR UPDATE OR DELETE ON osm_indoor_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE area_point.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON area_point.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE area_point.refresh();
