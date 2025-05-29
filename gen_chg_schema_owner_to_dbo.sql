SET NOCOUNT ON;

EXEC sp_MSforeachdb N'
IF DB_ID(''?'') > 4 -- Skip system databases
BEGIN
    USE [?];

    DECLARE @schema_name SYSNAME;
    DECLARE cur CURSOR FOR
    SELECT s.name
    FROM sys.schemas s
    JOIN sys.database_principals u ON s.principal_id = u.principal_id
    WHERE u.name NOT IN (
        ''dbo'', ''guest'', ''INFORMATION_SCHEMA'', ''sys'',
        ''db_owner'', ''db_accessadmin'', ''db_securityadmin'', ''db_ddladmin'',
        ''db_backupoperator'', ''db_datareader'', ''db_datawriter'',
        ''db_denydatareader'', ''db_denydatawriter''
    );

    OPEN cur;
    FETCH NEXT FROM cur INTO @schema_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT ''USE ['' + DB_NAME() + '']; ALTER AUTHORIZATION ON SCHEMA::['' + @schema_name + ''] TO [dbo];'';
        FETCH NEXT FROM cur INTO @schema_name;
    END

    CLOSE cur;
    DEALLOCATE cur;
END';
