BEGIN;
SELECT plan(3);

INSERT INTO osm_transportation_linestring
  (id, osm_id, class, conveying, geometry, level)
  VALUES
  (1, 626844375::bigint, 'steps', 'yes', ST_GeomFromText('LINESTRING(1 2, 3 4)', 3857), '1');

SELECT set_eq(
  'SELECT conveying FROM layer_transportation(ST_GeomFromText(''POLYGON((0 0, 0 2, 2 3, 2 0.5, 0 0))'', 3857), 17)',
  ARRAY['yes']
);

INSERT INTO osm_transportation_linestring
  (id, osm_id, class, conveying, geometry, level)
  VALUES
  (2, 626844375::bigint, 'steps', '', ST_GeomFromText('LINESTRING(1 2, 3 4)', 3857), '1');

SELECT set_eq(
  'SELECT conveying FROM layer_transportation(ST_GeomFromText(''POLYGON((0 0, 0 2, 2 3, 2 0.5, 0 0))'', 3857), 17)',
  ARRAY['yes', NULL]
);

INSERT INTO osm_transportation_linestring
  (id, osm_id, class, conveying, geometry, level)
  VALUES
  (2, 626844375::bigint, 'steps', 'no', ST_GeomFromText('LINESTRING(1 2, 3 4)', 3857), '1');

SELECT set_eq(
  'SELECT conveying FROM layer_transportation(ST_GeomFromText(''POLYGON((0 0, 0 2, 2 3, 2 0.5, 0 0))'', 3857), 17)',
  ARRAY['yes', NULL, NULL]
);

SELECT * FROM finish();
ROLLBACK;
