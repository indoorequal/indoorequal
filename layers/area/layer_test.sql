BEGIN;
SELECT plan(6);

INSERT INTO osm_indoor_polygon
  (id, osm_id, name, class, geometry, level, access, tags)
  VALUES
  (1, 626844375::bigint, 'test', 'area', ST_GeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 3857), '1', NULL, '');

SELECT set_eq(
  'SELECT id FROM layer_indoor(ST_GeomFromText(''POLYGON((0 0.5, 0 2, 2 3, 2 0.5, 0 0.5))'', 3857), 17)',
  ARRAY[-1]
);

INSERT INTO osm_indoor_polygon
  (id, osm_id, name, class, geometry, level, access, tags)
  VALUES
  (3, 626844377::bigint, 'test2', 'area', ST_GeomFromText('POLYGON((0 1, 0 2, 2 1, 1 1, 0 1))', 3857), '1',  NULL, '');

SELECT set_eq(
  'SELECT id FROM layer_indoor(ST_GeomFromText(''POLYGON((0 0.5, 0 2, 2 3, 2 0.5, 0 0.5))'', 3857), 17)',
  ARRAY[-1]
);

SELECT set_eq(
  'SELECT geometry FROM layer_indoor(ST_GeomFromText(''POLYGON((0 0.5, 0 2, 2 3, 2 0.5, 0 0.5))'', 3857), 17) where id=-1',
  'SELECT ST_UNION(
    ST_GeomFromText(''POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))'', 3857),
    ST_GeomFromText(''POLYGON((0 1, 0 2, 2 1, 1 1, 0 1))'', 3857)
  )'
);

INSERT INTO osm_indoor_polygon
  (id, osm_id, name, class, geometry, level, access, tags)
  VALUES
  (2, 626844376::bigint, 'test2', 'room', ST_GeomFromText('POLYGON((0 1, 0 2, 2 1, 1 1, 0 1))', 3857),  '1', NULL, '');

SELECT set_eq(
  'SELECT id FROM layer_indoor(ST_GeomFromText(''POLYGON((0 0.5, 0 2, 2 3, 2 0.5, 0 0.5))'', 3857), 17)',
  ARRAY[-1, 2]
);

INSERT INTO osm_indoor_polygon
  (id, osm_id, name, class, geometry, level, access, tags)
  VALUES
  (4, 626844376::bigint, 'test2', 'area', ST_GeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 3857), '1', NULL, 'shop=>supermarket');

SELECT set_eq(
  'SELECT id FROM layer_indoor(ST_GeomFromText(''POLYGON((0 0.5, 0 2, 2 3, 2 0.5, 0 0.5))'', 3857), 17)',
  ARRAY[-1, 2, 4]
);

INSERT INTO osm_indoor_polygon
  (id, osm_id, name, class, subclass, geometry, level)
  VALUES
  (1, 626844376::bigint, 'test', 'room', 'class', ST_GeomFromText('POLYGON((4 4, 4 5, 5 5, 5 4, 4 4))', 3857), '1');

SELECT set_eq(
  'SELECT subclass FROM layer_indoor(ST_GeomFromText(''POLYGON((3 3, 3 5, 5 6, 5 3, 3 3))'', 3857), 17)',
  ARRAY['class']
);

SELECT * FROM finish();
ROLLBACK;
