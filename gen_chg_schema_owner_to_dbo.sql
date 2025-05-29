SET NOCOUNT ON;

EXEC sp_MSforeachdb N'
IF DB_ID(''?'') > 4 -- Skip system databases
BEGIN
    USE [?];

    DECLARE @sql NVARCHAR(MAX) = '''';
    DECLARE @dbname SYSNAME = DB_NAME();

    SELECT @sql = @sql +
        ''USE ['' + @dbname + '']; ALTER AUTHORIZATION ON SCHEMA::['' + s.name + ''] TO [dbo];'' + CHAR(13) + CHAR(10)
    FROM sys.schemas s
    JOIN sys.database_principals u ON s.principal_id = u.principal_id
    WHERE u.name NOT IN (
        ''dbo'', ''guest'', ''INFORMATION_SCHEMA'', ''sys'',
        ''db_owner'', ''db_accessadmin'', ''db_securityadmin'', ''db_ddladmin'',
        ''db_backupoperator'', ''db_datareader'', ''db_datawriter'',
        ''db_denydatareader'', ''db_denydatawriter''
    );

    PRINT @sql;
END';
