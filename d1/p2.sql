CREATE TEMP TABLE lines (line text);
\copy lines FROM './input';

CREATE TEMP TABLE input (first int, second int);
INSERT INTO input (first, second)
SELECT
    (regexp_split_to_array(line, '\s+'))[1]::integer as col1,
    (regexp_split_to_array(line, '\s+'))[2]::integer as col2
FROM lines;

SELECT SUM(first * (SELECT COUNT(*) FROM input i2 WHERE i1.first = i2.second))
FROM input i1;
