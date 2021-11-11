DROP FUNCTION IF EXISTS repeat_on_to_array(repeat_on text);
CREATE FUNCTION repeat_on_to_array(repeat_on TEXT) RETURNS text[] AS $$
  SELECT array(
    SELECT generate_series(serie[1]::numeric, serie[2]::numeric) FROM (
      SELECT CASE
        WHEN level ~ '^(-?\d+)-(-?\d+)$' THEN regexp_match(level, '(-?\d+)-(-?\d+)')
        WHEN level ~ '^(-?\d+\.?\d?)$' THEN ARRAY[level, level]
        ELSE ARRAY[]::text[]
      END AS serie FROM unnest(string_to_array(repeat_on, ';')) as level)
    AS sub)::text[];
$$ LANGUAGE SQL IMMUTABLE;
