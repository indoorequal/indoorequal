DROP TRIGGER IF EXISTS trigger_flag_point ON osm_indoor_polygon;
DROP TRIGGER IF EXISTS trigger_refresh ON area_heatpoint.updates;

DROP MATERIALIZED VIEW IF EXISTS osm_area_heatpoint CASCADE;

CREATE MATERIALIZED VIEW osm_area_heatpoint AS (
    SELECT
        wp.osm_id, ST_PointOnSurface(wp.geometry) AS geometry
    FROM osm_indoor_polygon AS wp
);
CREATE INDEX IF NOT EXISTS osm_area_heatpoint_geometry_idx ON osm_area_heatpoint USING gist (geometry);

-- Handle updates

CREATE SCHEMA IF NOT EXISTS area_heatpoint;

CREATE TABLE IF NOT EXISTS area_heatpoint.updates(id serial primary key, t text, unique (t));
CREATE OR REPLACE FUNCTION area_heatpoint.flag() RETURNS trigger AS $$
BEGIN
    INSERT INTO area_heatpoint.updates(t) VALUES ('y')  ON CONFLICT(t) DO NOTHING;
    RETURN null;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION area_heatpoint.refresh() RETURNS trigger AS
  $BODY$
  BEGIN
    RAISE LOG 'Refresh area_heatpoint';
    REFRESH MATERIALIZED VIEW osm_area_heatpoint;
    DELETE FROM area_heatpoint.updates;
    RETURN null;
  END;
  $BODY$
language plpgsql;

CREATE TRIGGER trigger_flag_point
    AFTER INSERT OR UPDATE OR DELETE ON osm_indoor_polygon
    FOR EACH STATEMENT
    EXECUTE PROCEDURE area_heatpoint.flag();

CREATE CONSTRAINT TRIGGER trigger_refresh
    AFTER INSERT ON area_heatpoint.updates
    INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE area_heatpoint.refresh();
