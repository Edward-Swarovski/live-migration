SET NOCOUNT ON;

DECLARE @dbName NVARCHAR(256), @sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR FOR
SELECT name FROM sys.databases
WHERE database_id > 4 AND state_desc = 'ONLINE'
  AND name NOT IN ('SSISDB', 'ReportServer', 'ReportServerTempDB'); -- Exclude system DBs

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    USE [' + @dbName + '];

    -- Create User statements
    SELECT
        ''USE [' + @dbName + '];'' AS ScriptLine,
        ''IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = '''''' +
        CAST(dp.name COLLATE SQL_Latin1_General_CP1_CI_AS AS NVARCHAR(256)) + '''''')'' AS ScriptLine,
        ''CREATE USER ['' +
        CAST(dp.name COLLATE SQL_Latin1_General_CP1_CI_AS AS NVARCHAR(256)) +
        ''] FOR LOGIN ['' +
        CAST(sp.name COLLATE SQL_Latin1_General_CP1_CI_AS AS NVARCHAR(256)) +
        ''];'' AS ScriptLine
    FROM sys.database_principals dp
    RIGHT JOIN sys.server_principals sp ON dp.sid = sp.sid
    WHERE dp.type IN (''S'', ''U'', ''G'')
    AND dp.name NOT IN (''dbo'', ''guest'', ''INFORMATION_SCHEMA'', ''sys'');'

    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @dbName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;
