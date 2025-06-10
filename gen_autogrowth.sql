SET NOCOUNT ON;

SELECT 
    'USE [' + d.name + '];' + CHAR(13) +
    'ALTER DATABASE [' + d.name + '] MODIFY FILE (' +
    'NAME = N''' + mf.name + ''', ' +
    'FILEGROWTH = ' + 
    CASE 
        WHEN mf.is_percent_growth = 1 
            THEN CAST(mf.growth AS VARCHAR(10)) + '%' 
        ELSE CAST(mf.growth * 8 / 1024 AS VARCHAR(10)) + 'MB' 
    END + 
    ISNULL(', MAXSIZE = ' + 
        CASE 
            WHEN mf.max_size = -1 THEN 'UNLIMITED'
            ELSE CAST(mf.max_size * 8 / 1024 AS VARCHAR(10)) + 'MB'
        END, '') + 
    ');' AS [ALTER STATEMENT]
FROM 
    sys.master_files mf
JOIN 
    sys.databases d ON d.database_id = mf.database_id
WHERE 
    d.database_id > 4  -- exclude system DBs
ORDER BY 
    d.name, mf.type_desc;
