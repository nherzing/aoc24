CREATE TEMP TABLE lines (line text);
\copy lines FROM './sample';

CREATE TEMP TABLE input (first int, second int);
INSERT INTO input (first, second)
SELECT
    (regexp_split_to_array(line, '\s+'))[1]::integer as col1,
    (regexp_split_to_array(line, '\s+'))[2]::integer as col2
FROM lines;

WITH first AS (
    SELECT ROW_NUMBER() OVER() as rn, first
    FROM (SELECT first FROM input ORDER BY first) t
), second AS (
    SELECT ROW_NUMBER() OVER() as rn, second
    FROM (SELECT second FROM input ORDER BY second) t
), zipped AS (
    SELECT first.first, second.second
    FROM first
    JOIN second ON first.rn = second.rn
)
SELECT SUM(ABS(first - second))
FROM zipped;
