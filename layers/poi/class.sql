CREATE OR REPLACE FUNCTION poi_class_rank(class text)
    RETURNS int AS
$$
SELECT CASE class
           WHEN 'telephone' THEN 10
           WHEN 'information' THEN 10
           WHEN 'bank' THEN 50
           WHEN 'office' THEN 70
           WHEN 'shop' THEN 100
           WHEN 'clothing_store' THEN 100
           WHEN 'grocery' THEN 100
           WHEN 'fast_food' THEN 100
           WHEN 'laundry' THEN 200
           WHEN 'cafe' THEN 300
           WHEN 'bar' THEN 300
           WHEN 'beer' THEN 300
           WHEN 'vending_machine' THEN 700
           WHEN 'entrance' THEN 800
           ELSE 1000
           END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;

CREATE OR REPLACE FUNCTION poi_class(subclass text, mapping_key text)
    RETURNS text AS
$$
SELECT CASE
           -- Special case subclass collision between office=university and amenity=university
           WHEN mapping_key = 'amenity' AND subclass = 'university' THEN 'college'
           %%FIELD_MAPPING: class %%
           WHEN mapping_key IN ('door', 'entrance') THEN 'entrance'
           when mapping_key IN ('emergency', 'craft', 'aeroway') THEN mapping_key
           ELSE subclass
           END;
$$ LANGUAGE SQL IMMUTABLE
                PARALLEL SAFE;
