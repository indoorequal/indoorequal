BEGIN;
SELECT plan(5);

SELECT is(
    global_id_to_imposm('node:626844375'),
    626844375::bigint
);

SELECT is(
    global_id_to_imposm('way:626844375'),
    -626844375::bigint
);

SELECT is(
    global_id_to_imposm('relation:626844375'),
    -626844375-1e17::bigint
);

INSERT INTO osm_poi_polygon(id, osm_id, name, geometry, mapping_key, subclass, tags) VALUES(
       1,
       626844375::bigint,
       'test',
       ST_Transform(ST_GeomFromText('POINT(1 1)', 4326), 3857),
       'shop',
       'supermarket',
       'shop=>supermarket,opening_hours=>24/7'::hstore
);

INSERT INTO osm_poi_point(id, osm_id, name, geometry, mapping_key, subclass, tags) VALUES(
       1,
       626844376::bigint,
       'test',
       ST_Transform(ST_GeomFromText('POINT(1 1)', 4326), 3857),
       'shop',
       'supermarket',
       'shop=>supermarket'::hstore
);

SELECT is(
       get_poi('node:626844375'),
       '{"type": "Feature", "geometry": {"type":"Point","coordinates":[1,1]}, "properties": {"id": "node:626844375", "name": "test", "name_en": "test", "name_de": "test", "tags": {"shop": "supermarket", "opening_hours": "24/7"}, "class": "grocery", "subclass": "supermarket", "layer": null, "level": null, "indoor": null}}'
);

SELECT is(
       get_poi('node:626844376'),
       '{"type": "Feature", "geometry": {"type":"Point","coordinates":[1,1]}, "properties": {"id": "node:626844376", "name": "test", "name_en": "test", "name_de": "test", "tags": {"shop": "supermarket"}, "class": "grocery", "subclass": "supermarket", "layer": null, "level": null, "indoor": null}}'
);

SELECT * FROM finish();
ROLLBACK;
