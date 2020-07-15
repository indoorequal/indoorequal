CREATE OR REPLACE FUNCTION global_id_from_imposm(osm_id bigint)
RETURNS TEXT AS $$
    SELECT
        CASE WHEN osm_id < -1e17 THEN CONCAT('relation:', -osm_id-1e17)
             WHEN osm_id < 0 THEN CONCAT('way:', -osm_id)
             ELSE CONCAT('node:', osm_id)
        END
    ;
$$ LANGUAGE SQL IMMUTABLE;

-- etldoc: layer_poi[shape=record fillcolor=lightpink, style="rounded,filled",
-- etldoc:     label="layer_poi | <z12> z12 | <z13> z13 | <z17_> z17+" ] ;

DROP FUNCTION IF EXISTS layer_poi(geometry, integer, numeric);
CREATE FUNCTION layer_poi(bbox geometry, zoom_level integer, pixel_width numeric)
RETURNS TABLE(osm_id bigint, id text, geometry geometry, name text, name_en text, name_de text, tags hstore, class text, subclass text, agg_stop integer, layer integer, level numeric, indoor integer, "rank" int) AS $$
    SELECT osm_id_hash AS osm_id, global_id_from_imposm(osm_id) as id, geometry, NULLIF(name, '') AS name,
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
        agg_stop,
        NULLIF(layer, 0) AS layer,
        unnest(array_cat(string_to_array(level, ';'), repeat_on_to_array(repeat_on)))::numeric AS level,
        CASE WHEN indoor=TRUE THEN 1 ELSE NULL END as indoor,
        row_number() OVER (
            PARTITION BY LabelGrid(geometry, 100 * pixel_width)
            ORDER BY CASE WHEN name = '' THEN 2000 ELSE poi_class_rank(poi_class(subclass, mapping_key)) END ASC
        )::int AS "rank"
    FROM (
        -- etldoc: osm_poi_point ->  layer_poi:z12
        -- etldoc: osm_poi_point ->  layer_poi:z13
        SELECT *,
            osm_id*10 AS osm_id_hash
            FROM osm_poi_point
            WHERE geometry && bbox
                AND zoom_level BETWEEN 12 AND 13
                AND ((subclass='station' AND mapping_key = 'railway')
                    OR subclass IN ('halt', 'ferry_terminal'))
        UNION ALL

        -- etldoc: osm_poi_point ->  layer_poi:z17_
        SELECT *,
            osm_id*10 AS osm_id_hash
            FROM osm_poi_point
            WHERE geometry && bbox
                AND zoom_level >= 17

        UNION ALL
        -- etldoc: osm_poi_polygon ->  layer_poi:z12
        -- etldoc: osm_poi_polygon ->  layer_poi:z13
        SELECT *,
            NULL::INTEGER AS agg_stop,
            CASE WHEN osm_id<0 THEN -osm_id*10+4
                ELSE osm_id*10+1
            END AS osm_id_hash
        FROM osm_poi_polygon
            WHERE geometry && bbox
                AND zoom_level BETWEEN 12 AND 13
                AND ((subclass='station' AND mapping_key = 'railway')
                    OR subclass IN ('halt', 'ferry_terminal'))

        UNION ALL
        -- etldoc: osm_poi_polygon ->  layer_poi:z17_
        SELECT *,
            NULL::INTEGER AS agg_stop,
            CASE WHEN osm_id<0 THEN -osm_id*10+4
                ELSE osm_id*10+1
            END AS osm_id_hash
        FROM osm_poi_polygon
            WHERE geometry && bbox
                AND zoom_level >= 17
        ) as poi_union
    ORDER BY "rank"
    ;
$$ LANGUAGE SQL IMMUTABLE;
