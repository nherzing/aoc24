DROP TABLE IF EXISTS lines;
CREATE TEMP TABLE lines (line text);
\copy lines FROM './input';

WITH operands AS (
  SELECT regexp_matches(line, 'mul\((\d+),(\d+)\)', 'g')::int[] as ops from lines
),
prods AS (
  SELECT ops[1] * ops[2] as prod from operands
)
SELECT sum(prod) FROM prods
