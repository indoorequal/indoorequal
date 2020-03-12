
-- etldoc: layer_area_name[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_are_name | <z14_> z14+" ] ;

DROP FUNCTION IF EXISTS layer_area_name(geometry, integer, numeric);
CREATE FUNCTION layer_area_name(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(geometry geometry, name text, name_en text, name_de text, level numeric) AS $$
   -- etldoc: osm_area_name_* -> layer_transportation:z14_
   SELECT geometry, name, name_en, name_de, unnest(array_cat(string_to_array(level, ';'), repeat_on_to_array(repeat_on)))::numeric AS level
    FROM osm_area_point
    WHERE zoom_level >= 14 AND geometry && bbox;

$$ LANGUAGE SQL IMMUTABLE;
