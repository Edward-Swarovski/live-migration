SET NOCOUNT ON;

DECLARE @dbName NVARCHAR(256), @sql NVARCHAR(MAX);

DECLARE db_cursor CURSOR FOR
SELECT name FROM sys.databases
WHERE database_id > 4 AND state_desc = 'ONLINE'; -- Exclude system DBs

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = '
    USE [' + @dbName + '];

    DECLARE @dropSQL NVARCHAR(MAX) = '''';

    SELECT @dropSQL = @dropSQL +
        ''USE ['' + DB_NAME() + '']; DROP USER ['' + dp.name + ''];'' + CHAR(13) + CHAR(10)
    FROM sys.database_principals dp
    WHERE dp.name IN (
        ''NT SERVICE\MSSQLSERVER'',
        ''NT SERVICE\SQLSERVERAGENT'',
        ''NT AUTHORITY\NETWORKR SERVICE''
    );

    SELECT @dropSQL AS DropStatements;
    ';

    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @dbName;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;
