
----------------------------------------------------------------------------------
-- Enhanced Script: Generate Server-Level Permissions (Roles, Securables, Status)
-- Purpose: Generate GRANT, DENY, REVOKE for server logins including impersonation
-- Maintainer: ChatGPT - Enhanced for clarity and maintainability
----------------------------------------------------------------------------------

-- 1. Exclusion List (Customize Here)
DECLARE @ExcludedLogins TABLE (LoginName SYSNAME);
INSERT INTO @ExcludedLogins(LoginName)
VALUES 
    ('sa'), ('hp_dbspi'), ('dbadb_dbo'), 
    ('PRODUCTION\DbSysadminAll-Acc-G'), ('EUROPE\sys-dbaautosys-eu'),
    ('EUROPE\DBEngineering-ACC-GL'), ('EUROPE\DBSysadminAll-ACC-LON'),
    ('EUROPE\DBSysAdminAP-ACC-LON'), ('EUROPE\DBSysadminMUM-ACC-LON'),
    ('dbtools_copydb'), ('dbtools_restoredb'), ('mdscout'), 
    ('ASIAPAC\IN_AIMS_SQL_W'), ('public'), ('guest'),
    ('UK\LU SQL CA - Local Database Administrators'),
    ('UK\LU SQL CA - Remote Database Administrators');

-- 2. General Server Permissions (excluding 'IM')
SELECT 
    'BEGIN TRY ' + dp.state_desc + ' ' + dp.permission_name COLLATE DATABASE_DEFAULT + 
    ' TO [' + dpr.name + ']; ' +
    'END TRY BEGIN CATCH PRINT ''*Warning: unable to ' + dp.state_desc + ' ' + 
    dp.permission_name COLLATE DATABASE_DEFAULT + ' to [' + dpr.name + '] '' + ERROR_MESSAGE(); END CATCH' 
    AS GrantScript
FROM sys.server_permissions AS dp
INNER JOIN sys.server_principals AS dpr ON dp.grantee_principal_id = dpr.principal_id
WHERE dp.[type] <> 'IM'
    AND dpr.name NOT IN (SELECT LoginName FROM @ExcludedLogins)
    AND dpr.name NOT LIKE '##%##'
    AND dpr.name NOT LIKE 'NT %'
    AND dpr.name NOT LIKE 'EUROPE\sys-MS%';

-- 3. Impersonate Permissions ('IM' Type)
SELECT 
    'BEGIN TRY ' + perms.state_desc + ' ' + perms.permission_name COLLATE DATABASE_DEFAULT + 
    ' ON LOGIN::[' + grantor.name + '] TO [' + grantee.name + ']; ' +
    'END TRY BEGIN CATCH PRINT ''*Warning: unable to ' + perms.state_desc + ' ' +
    perms.permission_name COLLATE DATABASE_DEFAULT + ' ON LOGIN::[' + grantor.name + '] to [' + grantee.name + '] '' + ERROR_MESSAGE(); END CATCH'
    AS ImpersonateScript
FROM sys.server_permissions perms
INNER JOIN sys.server_principals grantor ON perms.grantor_principal_id = grantor.principal_id
INNER JOIN sys.server_principals grantee ON perms.grantee_principal_id = grantee.principal_id
WHERE perms.[type] = 'IM'
    AND grantee.name NOT IN (SELECT LoginName FROM @ExcludedLogins)
    AND grantee.name NOT LIKE '##%##'
    AND grantee.name NOT LIKE 'NT %'
    AND grantee.name NOT LIKE 'EUROPE\sys-MS%';
