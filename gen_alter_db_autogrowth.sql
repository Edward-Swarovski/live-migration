SET NOCOUNT ON;

WITH DatabaseSizes AS (
    SELECT
        database_id,
        SUM(CAST(size AS BIGINT) * 8.0 / 1024 / 1024) AS SizeGB
    FROM sys.master_files
    GROUP BY database_id
)
SELECT
    'USE [' + d.name + '];' + CHAR(13) +
    'ALTER DATABASE [' + d.name + '] MODIFY FILE (' +
    'NAME = N''' + mf.name + ''', ' +
    'FILEGROWTH = ' +
    CASE
        -- For Data Files
        WHEN mf.type_desc = 'ROWS' THEN
            CASE
                WHEN ds.SizeGB < 512 THEN '512MB'
                ELSE '1024MB'
            END
        -- For Log Files
        WHEN mf.type_desc = 'LOG' THEN
            CASE
                WHEN ds.SizeGB < 512 THEN '256MB'
                ELSE '512MB'
            END
    END +
    ', MAXSIZE = ' +
    CASE
        WHEN mf.max_size IN (-1, 268435456) THEN 'UNLIMITED'
        ELSE CAST(CAST(mf.max_size AS BIGINT) * 8 / 1024 AS VARCHAR(20)) + 'MB'
    END +
    ');' AS [ALTER STATEMENT]
FROM
    sys.master_files mf
JOIN
    sys.databases d ON d.database_id = mf.database_id
JOIN
    DatabaseSizes ds ON ds.database_id = d.database_id
WHERE
    d.database_id > 4  -- exclude system DBs
    AND d.name NOT IN ('SSISDB', 'ReportServer', 'ReportServerTempDB')
ORDER BY
    d.name, mf.type_desc;
