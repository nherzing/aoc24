DROP TABLE IF EXISTS lines;
CREATE TEMP TABLE lines (line text);
\copy lines FROM './input';

DROP TABLE IF EXISTS map;
CREATE TEMP TABLE map AS
WITH map AS (
  SELECT
    row_number() OVER () as line_number,
    line,
    regexp_split_to_array(line, '') as char_array
  FROM lines
)
SELECT
  line_number::integer as y,
  generate_subscripts(char_array, 1)::integer as x,
  unnest(char_array) as char
FROM map;

DROP FUNCTION IF EXISTS get_at;
CREATE FUNCTION get_at(pos integer[]) RETURNS char AS $$
    SELECT char
    FROM map
    WHERE map.x = pos[1] and map.y = pos[2];
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS move;
CREATE FUNCTION move(pos integer[], dir integer[]) RETURNS integer[] AS $$
    SELECT ARRAY[pos[1] + dir[1], pos[2] + dir[2]];
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS rotate;
CREATE FUNCTION rotate(dir integer[]) RETURNS integer[] AS $$
  SELECT CASE WHEN dir = ARRAY[0, -1] THEN ARRAY[1, 0]
       WHEN dir = ARRAY[1, 0] THEN ARRAY[0, 1]
       WHEN dir = ARRAY[0, 1] THEN ARRAY[-1, 0]
       WHEN dir = ARRAY[-1, 0] THEN ARRAY[0, -1]
  END;
$$ LANGUAGE SQL;

WITH RECURSIVE posdir AS (
  SELECT ARRAY[x, y] as pos, ARRAY[0, -1] as dir FROM map WHERE map.char = '^'
),
traverse AS (
  SELECT pos as pos, dir as dir, ARRAY[pos]::int[][] AS path
  FROM posdir
  UNION ALL
  SELECT
    CASE WHEN get_at(move(pos, dir)) = '#' THEN pos
         ELSE move(pos, dir)
    END as pos,
    CASE WHEN get_at(move(pos, dir)) IS NULL THEN dir
         WHEN get_at(move(pos, dir)) = '#' THEN rotate(dir)
         ELSE dir
    END as dir,
    CASE WHEN get_at(move(pos, dir)) IS NULL THEN path
         WHEN get_at(move(pos, dir)) = '#' THEN path
         ELSE path || move(pos, dir)
    END as path
  FROM traverse
  WHERE get_at(pos) IS NOT NULL
),
longest_path AS (
  SELECT distinct (path[i][1], path[i][2])
  FROM traverse, generate_subscripts(path, 1) i
  WHERE get_at(pos) IS NULL
)
select count(*) from longest_path;
