BEGIN;
SELECT plan(4);

INSERT INTO osm_indoor_polygon
  (id, osm_id, ref, name, class, geometry, level, access, tags)
  VALUES
  (1, 626844375::bigint, '', 'test', 'room', ST_GeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 3857), '1', NULL, 'shop=>supermarket');

REFRESH MATERIALIZED VIEW osm_area_point;

SELECT is(
  (SELECT count(*) FROM osm_area_point),
  0::bigint
);

INSERT INTO osm_indoor_polygon
  (id, osm_id, ref, name, class, geometry, level, access, tags)
  VALUES
  (1, 626844375::bigint, '1', '', 'room', ST_GeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 3857), '1', NULL, 'shop=>supermarket');

REFRESH MATERIALIZED VIEW osm_area_point;

SELECT is(
  (SELECT count(*) FROM osm_area_point),
  0::bigint
);


INSERT INTO osm_indoor_polygon
  (id, osm_id, ref, name, class, geometry, level, access, tags)
  VALUES
  (1, 626844376::bigint, '1', '', 'room', ST_GeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 3857), '1', NULL, '');

REFRESH MATERIALIZED VIEW osm_area_point;

SELECT is(
  (SELECT count(*) FROM osm_area_point),
  1::bigint
);

INSERT INTO osm_indoor_polygon
  (id, osm_id, ref, name, class, geometry, level, access, tags)
  VALUES
  (1, 626844376::bigint, '', 'test', 'room', ST_GeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 3857), '1', NULL, '');

REFRESH MATERIALIZED VIEW osm_area_point;

SELECT is(
  (SELECT count(*) FROM osm_area_point),
  2::bigint
);

SELECT * FROM finish();
ROLLBACK;
