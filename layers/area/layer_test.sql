BEGIN;
SELECT plan(1);


INSERT INTO osm_indoor_polygon(id, osm_id, name, class, geometry, level, access) VALUES(
       1,
       626844375::bigint,
       'test',
       'area',
       ST_GeomFromText('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))', 3857),
       '1',
       NULL
);

INSERT INTO osm_indoor_polygon(id, osm_id, name, class, geometry, level, access) VALUES(
       2,
       626844376::bigint,
       'test2',
       'area',
       ST_GeomFromText('POLYGON((0 1, 0 2, 2 1, 1 1, 0 1))', 3857),
       '2',
       'public'
);

SELECT set_eq(
       'SELECT id FROM layer_indoor(ST_GeomFromText(''POLYGON((0 0.5, 0 2, 2 3, 2 0.5, 0 0.5))'', 3857), 17, 1)',
       ARRAY[1, 2]
);

SELECT * FROM finish();
ROLLBACK;
