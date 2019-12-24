-- etldoc: layer_indoor[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_indoor | <z14_> z14+" ] ;

CREATE OR REPLACE FUNCTION layer_indoor(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(geometry geometry, class text, level real) AS $$
   -- etldoc: osm_indoor_* -> layer_indoor:z14_
   SELECT geometry, class, unnest(array_cat(string_to_array(level, ';'), repeat_on_to_array(repeat_on)))::real as level
   FROM (
      SELECT geometry, class, level, repeat_on
      FROM osm_indoor_polygon
      WHERE zoom_level >= 14 AND geometry && bbox
      UNION ALL
      SELECT geometry, class, level, repeat_on
      FROM osm_indoor_linestring
      WHERE zoom_level >= 14 AND geometry && bbox
   ) AS indoor_all;

$$ LANGUAGE SQL IMMUTABLE;
