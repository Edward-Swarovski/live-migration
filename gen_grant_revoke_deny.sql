
----------------------------------------------------------------------------------
-- Enhanced Script: Generate Server-Level Permissions (Roles, Securables, Status)
-- Purpose: Generate GRANT, DENY, REVOKE for server logins including impersonation
----------------------------------------------------------------------------------
/*
Usage: 
sqlcmd -SSQL07350,2500 -U sa_maint -i gen_grant_revoke_deny.sql  -o SQL07350_grant_revoke_deny.out -h -1 -W -P `cat sa_maint.pwd`
*/

SET NOCOUNT ON;
GO

-- 1. Exclusion List (Customize Here)
DECLARE @ExcludedLogins TABLE (LoginName SYSNAME);
INSERT INTO @ExcludedLogins(LoginName)
VALUES 

    ('##MS_PolicyEventProcessingLogin##'),
    ('##MS_PolicyTsqlExecutionLogin##'),
    ('a2pdba'),
    ('a2psysro'),
    ('BUILTIN\Administrators'),
    ('dbadb_dbo'),
    ('dbmsmon'),
    ('dbtools_copydb'),
    ('dbtools_restoredb'),
    ('dbtoolsp'),
    ('delphix_admin'),
    ('hp_dbspi'),
    ('infosec'),
    ('IT_SEC_ADMIN'),
    ('mdscout'),
    ('NT AUTHORITY\NETWORK SERVICE'),
    ('NT AUTHORITY\SYSTEM'),
    ('NT SERVICE\MSSQLSERVER'),
    ('NT SERVICE\SQLSERVERAGENT'),
    ('NT SERVICE\SQLTELEMETRY'),
    ('NT SERVICE\SQLWriter'),
    ('NT SERVICE\Winmgmt'),
    ('PRODUCTION\DBSysAdminAll-ACC-G'),
    ('PRODUCTION\sys-a2pdba1-g'),
    ('PRODUCTION\sys-a2pdba2-g'),
    ('QUALYS_DB'),
    ('sa'),
    ('sa_maint');

-- 2. General Server Permissions (excluding 'IM')

SELECT 
    'BEGIN TRY ' + 
    CASE 
        WHEN dp.state_desc = 'GRANT_WITH_GRANT_OPTION' THEN 
            'GRANT ' + dp.permission_name COLLATE DATABASE_DEFAULT + ' TO [' + dpr.name + '] WITH GRANT OPTION'
        ELSE 
            dp.state_desc + ' ' + dp.permission_name COLLATE DATABASE_DEFAULT + ' TO [' + dpr.name + ']'
    END + '; ' +
    'END TRY BEGIN CATCH PRINT ''*Warning: unable to ' + dp.state_desc + ' ' + 
    dp.permission_name COLLATE DATABASE_DEFAULT + ' to [' + dpr.name + '] '' + ERROR_MESSAGE(); END CATCH' 
    AS GrantScript
FROM sys.server_permissions AS dp
INNER JOIN sys.server_principals AS dpr ON dp.grantee_principal_id = dpr.principal_id
WHERE dp.[type] <> 'IM'
    AND dpr.name NOT IN (SELECT LoginName FROM @ExcludedLogins);

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
    AND grantee.name NOT IN (SELECT LoginName FROM @ExcludedLogins);
