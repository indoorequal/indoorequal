CREATE OR REPLACE FUNCTION global_id_to_imposm(global_id text)
RETURNS bigint AS $$
    DECLARE
        osm_type text := split_part($1, ':', 1);
        osm_id bigint := split_part(global_id, ':', 2)::bigint;
    BEGIN
      RETURN CASE
        WHEN osm_type='relation' THEN -osm_id-1e17
        WHEN osm_type='way' THEN -osm_id
        ELSE osm_id
     END;
   END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_poi(global_id text)
RETURNS TEXT AS $$
  SELECT  ST_AsGeoJSON(feature.*) FROM (
    SELECT global_id_from_imposm(osm_id) AS id,
          ST_Transform(geometry, 4326) AS geometry,
          NULLIF(name, '') AS name,
          COALESCE(NULLIF(name_en, ''), name) AS name_en,
          COALESCE(NULLIF(name_de, ''), name, name_en) AS name_de,
          tags,
          poi_class(subclass, mapping_key) AS class,
          CASE
              WHEN subclass = 'information'
                  THEN NULLIF(information, '')
              WHEN subclass = 'place_of_worship'
                      THEN NULLIF(religion, '')
              WHEN subclass = 'pitch'
                      THEN NULLIF(sport, '')
              WHEN subclass = 'vending_machine'
                      THEN NULLIF(vending, '')
              ELSE subclass
           END AS subclass,
        NULLIF(layer, 0) AS layer,
        level,
        CASE WHEN indoor=TRUE THEN 1 ELSE NULL END as indoor
        FROM (
             SELECT osm_id, geometry, name, name_en, name_de, tags, subclass, mapping_key, information, religion, sport, vending, layer, level, indoor
             FROM osm_poi_polygon
             WHERE osm_id=global_id_to_imposm(global_id)

             UNION ALL

             SELECT osm_id, geometry, name, name_en, name_de, tags, subclass, mapping_key, information, religion, sport, vending, layer, level, indoor
             FROM osm_poi_point
             WHERE osm_id=global_id_to_imposm(global_id)
        ) AS poi_union
  ) AS feature;
$$ LANGUAGE SQL IMMUTABLE;
