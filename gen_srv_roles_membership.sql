
----------------------------------------------------------------------------------
-- Enhanced Script: Generate Server Role Membership Scripts
-- Purpose: Re-grant server role memberships with version-safe logic and exclusions
----------------------------------------------------------------------------------
/*
Usage: 
sqlcmd -SSQL07350,2500 -U sa_maint -i gen_srv_roles_membership.sql  -o SQL07350_srv_roles_membership.out -h -1 -W -P `cat sa_maint.pwd`
*/
SET NOCOUNT ON;
GO

-- 1. Define Exclusion List for Login Names
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

----------------------------------------------------------------------------------
-- 2. Conditional Version Handling: Use ALTER SERVER ROLE or sp_addrolemember
----------------------------------------------------------------------------------
IF (CAST(CONVERT(VARCHAR(4), SERVERPROPERTY('ProductVersion')) AS FLOAT) > 9)
BEGIN
    SELECT 
        'BEGIN TRY ALTER SERVER ROLE [' + Rle.name + '] ADD MEMBER [' + mbr.name + ']; ' +
        'END TRY BEGIN CATCH PRINT ''*Warning: unable to add [' + mbr.name + '] to role [' + Rle.name + '] '' + ERROR_MESSAGE(); END CATCH' AS RoleScript
    FROM sys.server_role_members AS rm
    INNER JOIN sys.server_principals Rle ON rm.role_principal_id = Rle.principal_id
    INNER JOIN sys.server_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE mbr.name NOT IN (SELECT LoginName FROM @ExcludedLogins)
        AND mbr.name NOT LIKE '##%##'
        AND mbr.name NOT LIKE 'NT %'
        AND mbr.name NOT LIKE 'EUROPE\sys-MS%'
        AND mbr.name <> 'dbo'
        AND mbr.type <> 'R'
    ORDER BY rm.role_principal_id ASC;
END
ELSE
BEGIN
    SELECT 
        'BEGIN TRY EXEC sp_addrolemember @rolename = ' + QUOTENAME(Rle.name, '''') +
        ', @membername = ' + QUOTENAME(mbr.name, '''') + '; ' +
        'END TRY BEGIN CATCH PRINT ''*Warning: unable to add [' + mbr.name + '] to role [' + Rle.name + '] '' + ERROR_MESSAGE(); END CATCH' AS RoleScript
    FROM sys.server_role_members AS rm
    INNER JOIN sys.server_principals Rle ON rm.role_principal_id = Rle.principal_id
    INNER JOIN sys.server_principals mbr ON rm.member_principal_id = mbr.principal_id
    WHERE mbr.name NOT IN (SELECT LoginName FROM @ExcludedLogins)
        AND mbr.name NOT LIKE '##%##'
        AND mbr.name NOT LIKE 'NT %'
        AND mbr.name NOT LIKE 'EUROPE\sys-MS%'
        AND mbr.name <> 'dbo'
        AND mbr.type <> 'R'
    ORDER BY rm.role_principal_id ASC;
END
