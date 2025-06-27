SET NOCOUNT ON;
DECLARE @perm_sql NVARCHAR(MAX);
DECLARE @dbName NVARCHAR(256);

DECLARE perm_cursor CURSOR FOR
SELECT name FROM sys.databases
WHERE database_id > 4 AND state_desc = 'ONLINE'
  AND name NOT IN ('SSISDB', 'ReportServer', 'ReportServerTempDB'); -- Exclude system DBs

OPEN perm_cursor;
FETCH NEXT FROM perm_cursor INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @perm_sql = '
    USE [' + @dbName + '];

    SELECT
        ''USE [' + @dbName + '];'' AS ScriptLine,
        perm.state_desc + '' '' + perm.permission_name +
        CASE
            WHEN perm.class = 1 THEN '' ON ['' + CAST(s.name COLLATE SQL_Latin1_General_CP1_CI_AS AS NVARCHAR(256)) + ''].['' + CAST(o.name COLLATE SQL_Latin1_General_CP1_CI_AS AS NVARCHAR(256)) + '']''
            WHEN perm.class = 3 THEN '' ON SCHEMA::['' + CAST(s.name COLLATE SQL_Latin1_General_CP1_CI_AS AS NVARCHAR(256)) + '']''
            ELSE ''''
        END +
        '' TO ['' + CAST(dp.name COLLATE SQL_Latin1_General_CP1_CI_AS AS NVARCHAR(256)) + ''];'' AS PermissionScript
    FROM sys.database_permissions perm
    JOIN sys.database_principals dp ON perm.grantee_principal_id = dp.principal_id
    LEFT JOIN sys.objects o ON perm.major_id = o.object_id AND perm.class = 1
    LEFT JOIN sys.schemas s ON
        s.schema_id = ISNULL(o.schema_id, perm.major_id)
    WHERE dp.name NOT IN (''dbo'', ''guest'', ''INFORMATION_SCHEMA'', ''sys'')
      AND dp.type IN (''S'', ''U'', ''G'');
    ';

    EXEC sp_executesql @perm_sql;
    FETCH NEXT FROM perm_cursor INTO @dbName;
END

CLOSE perm_cursor;
DEALLOCATE perm_cursor;
