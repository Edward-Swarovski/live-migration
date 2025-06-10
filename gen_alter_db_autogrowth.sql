SET NOCOUNT ON;

SELECT 
    'USE [' + d.name + '];' + CHAR(13) +
    'ALTER DATABASE [' + d.name + '] MODIFY FILE (' +
    'NAME = N''' + mf.name + ''', ' +
    'FILEGROWTH = ' + 
    CASE 
        WHEN mf.is_percent_growth = 1 
            THEN CAST(mf.growth AS VARCHAR(10)) + '%' 
        ELSE CAST(CAST(mf.growth AS BIGINT) * 8 / 1024 AS VARCHAR(20)) + 'MB' 
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
WHERE 
    d.database_id > 4  -- exclude system DBs
ORDER BY 
    d.name, mf.type_desc;
