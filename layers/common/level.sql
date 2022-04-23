CREATE OR REPLACE FUNCTION level_to_array(level text)
RETURNS text[] AS $$
  SELECT array(
    SELECT generate_series(serie[1]::numeric, serie[2]::numeric) FROM (
      SELECT CASE
        WHEN level ~ '^(-?\d+)-(-?\d+)$' THEN regexp_match(level, '(-?\d+)-(-?\d+)')
        WHEN level ~ '^(-?\d+\.?\d?)$' THEN ARRAY[level, level]
        ELSE ARRAY[]::text[]
      END AS serie FROM unnest(string_to_array(level, ';')) as level)
    AS sub)::text[];
$$ LANGUAGE SQL IMMUTABLE;

CREATE OR REPLACE FUNCTION expand_levels(level text, repeat_on text)
RETURNS numeric[] as $$
  select
    array_cat(
      level_to_array(level),
      level_to_array(repeat_on)
    )::numeric[];
$$ LANGUAGE SQL IMMUTABLE;
