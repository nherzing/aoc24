DROP TABLE IF EXISTS lines;
CREATE TEMP TABLE lines (line text);
\copy lines FROM './input';

DROP TABLE IF EXISTS rules;
CREATE TEMP TABLE rules AS
SELECT
  (regexp_matches(line, '(\d+)\|(\d+)'))[1] as a,
  (regexp_matches(line, '(\d+)\|(\d+)'))[2] as b
FROM lines
WHERE line ~ '(\d+)\|(\d+)';

DROP TABLE IF EXISTS updates;
CREATE TEMP TABLE updates AS
SELECT
    update_num,
    el,
    idx as index
FROM
    (SELECT line, ROW_NUMBER() OVER () as update_num FROM lines) l,
    unnest(string_to_array(line, ',')) WITH ORDINALITY AS t(el, idx)
WHERE line ~ ',';

DROP TABLE IF EXISTS invalids;
CREATE TEMP TABLE invalids AS
WITH valids AS (
  SELECT u.update_num, array_agg(u.el), array_position(array_agg(a), NULL) IS NULL as valid
  FROM updates u
  JOIN updates u2 ON u2.update_num = u.update_num AND u2.index > u.index
  LEFT JOIN rules r ON r.a = u.el AND r.b = u2.el
  GROUP BY u.update_num
  ORDER BY u.update_num
)
SELECT u.update_num, u.el, u.index
FROM valids v
JOIN updates u on u.update_num = v.update_num
WHERE NOT valid;

DROP FUNCTION IF EXISTS get_first;
CREATE FUNCTION get_first(xs text[]) RETURNS text AS $$
WITH els AS (
  SELECT unnest(xs) AS el
),
pairs AS (
  SELECT
    a.el AS el1,
    b.el AS el2
  FROM els a, els b
  WHERE a.el <> b.el
),
valids AS (
  SELECT el1, array_position(array_agg(a), NULL) IS NULL as valid
  FROM pairs
  LEFT JOIN rules r ON r.a = el1 AND r.b = el2
  GROUP BY el1
)
SELECT el1 FROM valids WHERE valid
$$ LANGUAGE SQL;

WITH RECURSIVE arrs AS (
  SELECT array_agg(el) as arr
  FROM invalids
  GROUP BY update_num
  ORDER BY update_num
),
solve AS (
  SELECT arr as rem, ARRAY[]::text[] as result
  FROM arrs
  UNION ALL
  SELECT
    CASE WHEN array_length(rem, 1) = 1 THEN ARRAY[]::text[]
         ELSE array_remove(rem, get_first(rem))
    END as rem,
    CASE WHEN array_length(rem, 1) = 1 THEN array_append(result, rem[1])
         ELSE array_append(result, get_first(rem))
    END as result
  FROM solve
  WHERE rem <> ARRAY[]::text[]
),
results AS (
  SELECT result from solve WHERE rem = ARRAY[]::text[]
),
middles AS (
  SELECT result[array_length(result, 1) / 2 + 1] m
  FROM results v
)
SELECT SUM(m::integer) FROM middles;
