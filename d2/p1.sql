DROP TABLE IF EXISTS lines;
CREATE TEMP TABLE lines (line text);
\copy lines FROM './input';

WITH line_nums as (
  SELECT regexp_split_to_array(line, '\s+')::int[] as arr
FROM lines
), diffs as (
  SELECT
    arr,
    array_agg(t.a - t.b) as diffs
  FROM line_nums,
    unnest(arr[1:array_length(arr,1)-1], arr[2:]) AS t(a,b)
  GROUP BY arr
), safe as (
  SELECT
    (-3 <= ALL (select unnest(diffs)) AND
     -1 >= ALL (select unnest(diffs))) OR
    (1 <= ALL (select unnest(diffs)) AND
     3 >= ALL (select unnest(diffs)))
    as safe
  FROM diffs
)
SELECT COUNT(*) from safe where safe.safe;
