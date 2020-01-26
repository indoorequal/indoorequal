
-- etldoc: layer_transportation[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_transportation | <z14_> z14+" ] ;

DROP FUNCTION IF EXISTS layer_transportation(geometry, integer, numeric);
CREATE FUNCTION layer_transportation(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(geometry geometry, class text, conveying text, level numeric) AS $$
   -- etldoc: osm_transportation_* -> layer_transportation:z14_
   SELECT geometry, class, NULLIF(conveying, '') AS conveying, unnest(array_cat(string_to_array(level, ';'), repeat_on_to_array(repeat_on)))::numeric AS level
    FROM osm_transportation_linestring
    WHERE zoom_level >= 14 AND geometry && bbox;

$$ LANGUAGE SQL IMMUTABLE;
