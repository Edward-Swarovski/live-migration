SET NOCOUNT ON;

DECLARE @dbName NVARCHAR(256), @sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR FOR
SELECT name FROM sys.databases
WHERE database_id > 4 AND state_desc = 'ONLINE'; -- Exclude system DBs

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    USE [' + @dbName + '];

    -- Generate ALTER ROLE only for mapped users (non-orphaned)
    SELECT
        ''USE [' + @dbName + '];'' AS ScriptLine,
        ''ALTER ROLE ['' + CAST(dr.name COLLATE SQL_Latin1_General_CP1_CI_AS AS NVARCHAR(256)) + ''] ADD MEMBER ['' + CAST(dp.name COLLATE SQL_Latin1_General_CP1_CI_AS AS NVARCHAR(256)) + ''];'' AS ScriptLine
    FROM sys.database_principals dp
    JOIN sys.database_role_members drm ON dp.principal_id = drm.member_principal_id
    JOIN sys.database_principals dr ON drm.role_principal_id = dr.principal_id
    LEFT JOIN sys.server_principals sp ON dp.sid = sp.sid
    WHERE dp.type IN (''S'', ''U'', ''G'')
      AND dp.name NOT IN (''dbo'', ''guest'', ''INFORMATION_SCHEMA'', ''sys'')
      AND sp.name IS NOT NULL; -- Only mapped users (non-orphaned)
    ';

    EXEC sp_executesql @sql;
    FETCH NEXT FROM db_cursor INTO @dbName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;
