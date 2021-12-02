CREATE OR REPLACE FUNCTION is_poi(tags HSTORE)
RETURNS boolean AS $$
    BEGIN
      RETURN tags ?| ARRAY['amenity', 'shop', 'craft', 'leisure', 'office', 'sport', 'tourism', 'exhibit', 'door'];
    END
$$ LANGUAGE plpgsql;
