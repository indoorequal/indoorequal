-- etldoc: layer_indoor[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_indoor | <z14_> z14+" ] ;

DROP FUNCTION IF EXISTS layer_indoor(geometry, integer, numeric);
CREATE FUNCTION layer_indoor(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(geometry geometry, class text, level numeric, access string) AS $$
   SELECT geometry, class, unnest(array_cat(string_to_array(level, ';'), repeat_on_to_array(repeat_on)))::numeric as level, access
   FROM (
      -- etldoc: osm_indoor_polygon -> layer_indoor:z14_
      SELECT geometry, class, level, repeat_on, access
      FROM osm_indoor_polygon
      WHERE zoom_level >= 14 AND geometry && bbox
      UNION ALL
      -- etldoc: osm_indoor_linestring -> layer_indoor:z14_
      SELECT geometry, class, level, repeat_on, NULL as access
      FROM osm_indoor_linestring
      WHERE zoom_level >= 14 AND geometry && bbox
   ) AS indoor_all;

$$ LANGUAGE SQL IMMUTABLE;
