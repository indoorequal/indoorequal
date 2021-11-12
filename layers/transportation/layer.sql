
-- etldoc: layer_transportation[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_transportation | <z17_> z17+" ] ;

DROP FUNCTION IF EXISTS layer_transportation(geometry, integer, numeric);
DROP FUNCTION IF EXISTS layer_transportation(geometry, integer);
CREATE FUNCTION layer_transportation(bbox geometry, zoom_level integer)
RETURNS TABLE(geometry geometry, class text, conveying text, level numeric) AS $$
   -- etldoc: osm_transportation_linestring -> layer_transportation:z17_
   SELECT geometry, class, NULLIF(NULLIF(conveying, ''), 'no') AS conveying, unnest(expand_levels(level, repeat_on)) AS level
    FROM osm_transportation_linestring
    WHERE zoom_level >= 17 AND geometry && bbox;

$$ LANGUAGE SQL IMMUTABLE;
