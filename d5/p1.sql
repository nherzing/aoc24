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

WITH valids AS (
  SELECT u.update_num, array_agg(u.el), array_position(array_agg(a), NULL) IS NULL as valid
  FROM updates u
  JOIN updates u2 ON u2.update_num = u.update_num AND u2.index > u.index
  LEFT JOIN rules r ON r.a = u.el AND r.b = u2.el
  GROUP BY u.update_num
  ORDER BY u.update_num
),
middles AS (
  SELECT (array_agg(u.el))[array_length(array_agg(u.el), 1) / 2 + 1] m
  FROM valids v
  JOIN updates u on u.update_num = v.update_num
  WHERE valid
  GROUP BY u.update_num
  ORDER BY u.update_num
)
SELECT SUM(m::integer) FROM middles;
