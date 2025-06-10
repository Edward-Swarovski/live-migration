USE master;
GO

-- Create a temporary table to store login details
IF OBJECT_ID('tempdb..#Logins') IS NOT NULL
    DROP TABLE #Logins;

CREATE TABLE #Logins (
    LoginName NVARCHAR(128),
    SID VARBINARY(85),
    PasswordHash VARBINARY(256),
    DefaultDatabase NVARCHAR(128),
    IsDisabled BIT
);

-- Insert SQL Server logins into the temp table (excluding system and excluded logins)
INSERT INTO #Logins (LoginName, SID, PasswordHash, DefaultDatabase, IsDisabled)
SELECT 
    name AS LoginName,
    sid AS SID,
    password_hash AS PasswordHash,
    default_database_name AS DefaultDatabase,
    is_disabled AS IsDisabled
FROM sys.sql_logins
WHERE type = 'S'
AND name NOT IN (
    '##MS_PolicyEventProcessingLogin##',
    '##MS_PolicyTsqlExecutionLogin##',
    'a2pdba',
    'a2psysro',
    'BUILTIN\Administrators',
    'dbadb_dbo',
    'dbmsmon',
    'dbtools_copydb',
    'dbtools_restoredb',
    'dbtoolsp',
    'delphix_admin',
    'hp_dbspi',
    'infosec',
    'IT_SEC_ADMIN',
    'mdscout',
    'NT AUTHORITY\NETWORK SERVICE',
    'NT AUTHORITY\SYSTEM',
    'NT SERVICE\MSSQLSERVER',
    'NT SERVICE\SQLSERVERAGENT',
    'NT SERVICE\SQLTELEMETRY',
    'NT SERVICE\SQLWriter',
    'NT SERVICE\Winmgmt',
    'PRODUCTION\DBSysAdminAll-ACC-G',
    'PRODUCTION\sys-a2pdba1-g',
    'PRODUCTION\sys-a2pdba2-g',
    'QUALYS_DB',
    'sa',
    'sa_maint'
);

-- Generate DROP and CREATE LOGIN statements
SELECT 
    'BEGIN TRY ' +
        'IF EXISTS (SELECT * FROM sys.sql_logins WHERE name = ''' + LoginName + ''') ' +
        'DROP LOGIN [' + LoginName + ']; ' +
        'CREATE LOGIN [' + LoginName + '] ' +
        'WITH PASSWORD = ' + CONVERT(VARCHAR(MAX), PasswordHash, 1) + ' HASHED, ' +
        'SID = ' + CONVERT(VARCHAR(MAX), SID, 1) + ', ' +
        'DEFAULT_DATABASE = [' + DefaultDatabase + '], ' +
        'CHECK_POLICY = OFF; ' +
        CASE WHEN IsDisabled = 1 THEN 'ALTER LOGIN [' + LoginName + '] DISABLE; ' ELSE '' END +
    'END TRY ' +
    'BEGIN CATCH ' +
        'PRINT ''Failed to recreate login: [' + LoginName + '] - Error: '' + ERROR_MESSAGE(); ' +
    'END CATCH;' AS LoginScript
FROM #Logins
ORDER BY LoginName;

-- Clean up
DROP TABLE #Logins;
