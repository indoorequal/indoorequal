-- etldoc: layer_indoor[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_indoor | <z14_> z14+" ] ;

DROP FUNCTION IF EXISTS layer_indoor(geometry, integer, numeric);
CREATE FUNCTION layer_indoor(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(id integer, geometry geometry, class text, is_poi boolean, level numeric, access text) AS $$
  WITH
  areas AS (
    SELECT
          id,
          geometry,
          class,
          unnest(array_cat(
                  string_to_array(level, ';'),
                  repeat_on_to_array(repeat_on)
          ))::numeric as level,
          access,
          tags
     FROM (
        -- etldoc: osm_indoor_polygon -> layer_indoor:z14_
        SELECT id, geometry, class, level, repeat_on, access, tags
        FROM osm_indoor_polygon
        WHERE zoom_level >= 14 AND geometry && bbox
        UNION ALL
        -- etldoc: osm_indoor_linestring -> layer_indoor:z14_
        SELECT id, geometry, class, level, repeat_on, NULL as access, NULL AS tags
        FROM osm_indoor_linestring
        WHERE zoom_level >= 14 AND geometry && bbox
     ) AS indoor_all
   ),
   unwalled_areas AS (
     SELECT *
     FROM areas
     WHERE class IN ('area', 'corridor', 'platform')
   )

   SELECT *
   FROM (
     SELECT -1 AS id, ST_UNION(geometry) AS geometry, 'area' as class, FALSE AS is_poi, level, access
     FROM unwalled_areas
     WHERE NOT is_poi(tags)
     GROUP BY level, access

     UNION ALL

     SELECT id, geometry, class, TRUE AS is_poi, level, access
     FROM unwalled_areas
     WHERE is_poi(tags)

     UNION ALL

     SELECT id, geometry, class, is_poi(tags) AS is_poi, level, access
     FROM areas
     WHERE class NOT IN ('area', 'corridor', 'platform')
   ) AS indoor_merged;
$$ LANGUAGE SQL IMMUTABLE;
