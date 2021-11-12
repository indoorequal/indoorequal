CREATE OR REPLACE FUNCTION expand_levels(level text, repeat_on text)
RETURNS numeric[] as $$
  select
    array_cat(
      string_to_array(level, ';'),
      repeat_on_to_array(repeat_on)
    )::numeric[];
$$ LANGUAGE SQL IMMUTABLE;
