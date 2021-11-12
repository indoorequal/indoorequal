-- etldoc: layer_indoor[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_indoor | <z17_> z17+" ] ;

DROP FUNCTION IF EXISTS layer_indoor(geometry, integer, numeric);
DROP FUNCTION IF EXISTS layer_indoor(geometry, integer);
CREATE FUNCTION layer_indoor(bbox geometry, zoom_level integer)
RETURNS TABLE(id integer, geometry geometry, class text, subclass text, is_poi boolean, level numeric, access text) AS $$
  WITH
  areas AS (
    SELECT
          id,
          geometry,
          class,
          subclass,
          unnest(expand_levels(level, repeat_on)) as level,
          access,
          tags
     FROM (
        -- etldoc: osm_indoor_polygon -> layer_indoor:z17_
        SELECT id, geometry, class, subclass, level, repeat_on, access, tags
        FROM osm_indoor_polygon
        WHERE zoom_level >= 17 AND geometry && bbox
        UNION ALL
        -- etldoc: osm_indoor_linestring -> layer_indoor:z17_
        SELECT id, geometry, class, NULL as subclass, level, repeat_on, NULL as access, NULL AS tags
        FROM osm_indoor_linestring
        WHERE zoom_level >= 17 AND geometry && bbox
     ) AS indoor_all
   ),
   unwalled_areas AS (
     SELECT *
     FROM areas
     WHERE class IN ('area', 'corridor', 'platform')
   )

   SELECT *
   FROM (
     SELECT -1 AS id, ST_UNION(geometry) AS geometry, 'area' as class, NULL as subclass, FALSE AS is_poi, level, access
     FROM unwalled_areas
     WHERE NOT is_poi(tags)
     GROUP BY level, access

     UNION ALL

     SELECT id, geometry, class, subclass, TRUE AS is_poi, level, access
     FROM unwalled_areas
     WHERE is_poi(tags)

     UNION ALL

     SELECT id, geometry, class, subclass, is_poi(tags) AS is_poi, level, access
     FROM areas
     WHERE class NOT IN ('area', 'corridor', 'platform')
   ) AS indoor_merged;
$$ LANGUAGE SQL IMMUTABLE;
