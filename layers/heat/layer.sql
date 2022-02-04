
-- etldoc: layer_heat[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_heat | <z0_17> z0-17" ] ;

DROP FUNCTION IF EXISTS layer_heat(geometry);
DROP FUNCTION IF EXISTS layer_heat(geometry, integer);
CREATE FUNCTION layer_heat(bbox geometry, zoom_level integer)
RETURNS TABLE(id bigint, geometry geometry) AS $$
   -- etldoc: osm_area_heatpoint -> layer_heat:z0_17
   SELECT osm_id AS id, geometry
    FROM osm_area_heatpoint
    WHERE zoom_level < %%VAR:indoor_zoom%% AND geometry && bbox;

$$ LANGUAGE SQL IMMUTABLE;
