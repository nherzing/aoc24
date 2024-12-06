DROP TABLE IF EXISTS lines;
CREATE TEMP TABLE lines (line text);
\copy lines FROM './input';

DROP TABLE IF EXISTS chars;
CREATE TEMP TABLE chars AS
WITH chars AS (
  SELECT
    row_number() OVER () as line_number,
    line,
    regexp_split_to_array(line, '') as char_array
  FROM lines
)
SELECT
  line_number as y,
  generate_subscripts(char_array, 1) as x,
  unnest(char_array) as char
FROM chars;

DROP FUNCTION IF EXISTS get_at;
CREATE FUNCTION get_at(xi integer, yi integer) RETURNS char AS $$
    SELECT char
    FROM chars
    WHERE chars.x = xi and chars.y = yi;
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS tries;
CREATE FUNCTION tries(x integer, y integer) RETURNS text[] AS $$
    SELECT ARRAY[
             array_to_string(ARRAY[get_at(x, y), get_at(x+1, y), get_at(x+2, y), get_at(x+3, y)], ''),
             array_to_string(ARRAY[get_at(x, y), get_at(x-1, y), get_at(x-2, y), get_at(x-3, y)], ''),
             array_to_string(ARRAY[get_at(x, y), get_at(x, y+1), get_at(x, y+2), get_at(x, y+3)], ''),
             array_to_string(ARRAY[get_at(x, y), get_at(x, y-1), get_at(x, y-2), get_at(x, y-3)], ''),
             array_to_string(ARRAY[get_at(x, y), get_at(x+1, y+1), get_at(x+2, y+2), get_at(x+3, y+3)], ''),
             array_to_string(ARRAY[get_at(x, y), get_at(x+1, y-1), get_at(x+2, y-2), get_at(x+3, y-3)], ''),
             array_to_string(ARRAY[get_at(x, y), get_at(x-1, y+1), get_at(x-2, y+2), get_at(x-3, y+3)], ''),
             array_to_string(ARRAY[get_at(x, y), get_at(x-1, y-1), get_at(x-2, y-2), get_at(x-3, y-3)], '')
           ] from lines;
$$ LANGUAGE SQL;

WITH coords AS (
  SELECT * FROM generate_series(1, (SELECT count(*) FROM lines)) as x, generate_series(1, (SELECT max(length(line)) from lines)) as y
),
tries AS (
  SELECT tries(x::integer, y) as try FROM coords
),
valid AS (
  SELECT array_length(array_positions(try, 'XMAS'), 1) as c
  FROM tries
)
SELECT sum(c) FROM valid;
