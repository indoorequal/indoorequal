
-- etldoc: layer_barrier[shape=record fillcolor=lightpink,
-- etldoc:     style="rounded,filled", label="layer_barrier | <z17_> z17+" ] ;

DROP FUNCTION IF EXISTS layer_barrier(geometry, integer);
CREATE FUNCTION layer_barrier(bbox geometry, zoom_level integer)
RETURNS TABLE(geometry geometry, class text, level numeric) AS $$
   -- etldoc: osm_barrier_linestring -> layer_barrier:z17_
   SELECT geometry, class, unnest(expand_levels(level, repeat_on)) AS level
   FROM osm_barrier_linestring
   WHERE zoom_level >= %%VAR:indoor_zoom%% AND geometry && bbox
   UNION ALL
   -- etldoc: osm_barrier_point -> layer_barrier:z17_
   SELECT geometry, class, unnest(expand_levels(level, repeat_on)) AS level
   FROM osm_barrier_point
   WHERE zoom_level >= %%VAR:indoor_zoom%% AND geometry && bbox
   ;

$$ LANGUAGE SQL IMMUTABLE;
