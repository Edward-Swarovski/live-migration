USE master;
GO

-- Create temp table to store all desired login details
IF OBJECT_ID('tempdb..#Logins') IS NOT NULL
    DROP TABLE #Logins;

CREATE TABLE #Logins (
    LoginName NVARCHAR(128),
    SID VARBINARY(85),
    TypeDesc NVARCHAR(60),
    PasswordHash VARBINARY(256),
    DefaultDatabase NVARCHAR(128),
    IsDisabled BIT
);

-- Insert SQL-authenticated logins
INSERT INTO #Logins (LoginName, SID, TypeDesc, PasswordHash, DefaultDatabase, IsDisabled)
SELECT 
    name,
    sid,
    type_desc,
    password_hash,
    default_database_name,
    is_disabled
FROM sys.sql_logins
WHERE name NOT IN (
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

-- Insert Windows-authenticated logins
INSERT INTO #Logins (LoginName, SID, TypeDesc, PasswordHash, DefaultDatabase, IsDisabled)
SELECT 
    name,
    sid,
    type_desc,
    NULL AS password_hash,
    NULL AS default_database_name,
    is_disabled
FROM sys.server_principals
WHERE type_desc = 'WINDOWS_LOGIN'
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

-- Generate drop and recreate login statements
SELECT 
    'BEGIN TRY ' +
        'IF EXISTS (SELECT * FROM sys.server_principals WHERE name = ''' + LoginName + ''') ' +
        'DROP LOGIN [' + LoginName + ']; ' +
        CASE 
            WHEN TypeDesc = 'SQL_LOGIN' THEN 
                'CREATE LOGIN [' + LoginName + '] ' +
                'WITH PASSWORD = ' + CONVERT(VARCHAR(MAX), PasswordHash, 1) + ' HASHED, ' +
                'SID = ' + CONVERT(VARCHAR(MAX), SID, 1) + 
                ISNULL(', DEFAULT_DATABASE = [' + DefaultDatabase + ']', '') + ', CHECK_POLICY = OFF; '
            WHEN TypeDesc = 'WINDOWS_LOGIN' THEN 
                'CREATE LOGIN [' + LoginName + '] FROM WINDOWS WITH SID = ' + CONVERT(VARCHAR(MAX), SID, 1) + '; '
            ELSE '-- Skipped unsupported type: ' + TypeDesc
        END +
        CASE WHEN IsDisabled = 1 THEN 'ALTER LOGIN [' + LoginName + '] DISABLE; ' ELSE '' END +
    'END TRY ' +
    'BEGIN CATCH ' +
        'PRINT ''Failed to recreate login: [' + LoginName + '] - Error: '' + ERROR_MESSAGE(); ' +
    'END CATCH;' AS LoginScript
FROM #Logins
ORDER BY LoginName;

-- Clean up
DROP TABLE #Logins;
