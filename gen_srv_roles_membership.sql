
----------------------------------------------------------------------------------
-- Enhanced Script: Generate Server Role Membership Scripts
-- Purpose: Re-grant server role memberships with version-safe logic and exclusions
-- Maintainer: ChatGPT - Enhanced for clarity and maintainability
----------------------------------------------------------------------------------
SET NOCOUNT ON;
GO

-- 1. Define Exclusion List for Login Names
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
    ('UK\LU SQL CA - Remote Database Administrators'),
    ('NT AUTHORITY\SYSTEM');

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
