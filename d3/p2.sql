DROP TABLE IF EXISTS lines;
CREATE TEMP TABLE lines (line text);
\copy lines FROM './input';

WITH single_line AS (
  SELECT string_agg(line, '\n') as line FROM lines
),
groups AS (
  SELECT regexp_split_to_table(line, '(?=don''t\(\)|do\(\))')::text as g
  FROM single_line
),
good_groups AS (
  SELECT
    g
  FROM groups
  WHERE (
    CASE WHEN g ~ '^do\(\)' THEN true
    WHEN g ~ '^don''t\(\)' THEN false
    ELSE true
    END
  )
),
operands AS (
  SELECT
    g,
    regexp_matches(g, 'mul\((\d+),(\d+)\)', 'g')::int[] as ops
  FROM good_groups
), prods AS (
  SELECT ops[1] * ops[2] as prod from operands
)
SELECT sum(prod) FROM prods
