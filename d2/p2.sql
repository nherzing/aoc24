DROP TABLE IF EXISTS lines;
CREATE TEMP TABLE lines (line text);
\copy lines FROM './input';

WITH line_nums AS (
	SELECT regexp_split_to_array(line, '\s+')::int[] AS arr
	FROM lines
),
with_indices AS (
	SELECT
		arr,
		generate_subscripts(arr, 1) AS idx
	FROM line_nums
),
reports AS (
	SELECT
		arr,
		CASE WHEN idx = 0 THEN
			arr
		WHEN idx = 1 THEN
			arr[2:]
		ELSE
			arr[1:idx - 1] || arr[idx + 1:]
		END AS report
	FROM with_indices
),
diffs AS (
	SELECT
		arr,
		report,
		array_agg(t.a - t.b ORDER BY ORDINALITY) AS diffs
	FROM
		reports,
		unnest(report[1:array_length(report, 1) - 1], report[2:])
		WITH ORDINALITY AS t (a, b, ORDINALITY)
	GROUP BY arr, report
),
safe AS (
  SELECT
    arr,
    (-3 <= ALL (SELECT unnest(diffs)) AND -1 >= ALL (SELECT unnest(diffs)))
		OR
		(1 <= ALL (SELECT unnest(diffs)) AND 3 >= ALL (SELECT unnest(diffs)))
		AS safe
		FROM diffs
),
grouped_safe AS (
	SELECT
		arr,
		bool_or(safe) AS safe
	FROM safe
	GROUP BY arr
)
SELECT count(*)
FROM grouped_safe
WHERE safe;
