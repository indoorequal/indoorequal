
-- etldoc: layer_heat[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_heat | <z0_> z0+" ] ;

DROP FUNCTION IF EXISTS layer_heat(geometry);
CREATE FUNCTION layer_heat(bbox geometry)
RETURNS TABLE(id bigint, geometry geometry) AS $$
   -- etldoc: osm_area_heatpoint -> layer_heat:z0_
   SELECT osm_id AS id, geometry
    FROM osm_area_heatpoint
    WHERE geometry && bbox;

$$ LANGUAGE SQL IMMUTABLE;
