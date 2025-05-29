SET NOCOUNT ON;

-- To list out the orphaned users
IF OBJECT_ID('tempdb..#users', 'U') IS NOT NULL
BEGIN
    DROP TABLE #users
END

CREATE TABLE #users (
    dbname varchar(128),
    dbusername varchar(128),
    create_date datetime,
    modifydate datetime,
    owningid int
);

-- First, create a table of user databases
IF OBJECT_ID('tempdb..#userDatabases', 'U') IS NOT NULL
BEGIN
    DROP TABLE #userDatabases
END

CREATE TABLE #userDatabases (
    dbname varchar(128)
);

-- Get only user databases
INSERT INTO #userDatabases
SELECT name
FROM sys.databases
WHERE database_id > 4
AND state_desc = 'ONLINE';

-- Use dynamic SQL to process each user database
DECLARE @sql NVARCHAR(MAX);
DECLARE @dbname VARCHAR(128);

DECLARE db_cursor CURSOR FOR
SELECT dbname FROM #userDatabases;

OPEN db_cursor;
FETCH NEXT FROM db_cursor INTO @dbname;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    USE [' + @dbname + '];
    INSERT INTO #users
    SELECT
        DB_NAME(),
        dp.name,
        dp.create_date,
        dp.modify_date,
        dp.owning_principal_id
    FROM sys.database_principals dp
    LEFT OUTER JOIN sys.server_principals sp ON dp.sid = sp.sid
    WHERE sp.name IS NULL
    AND dp.type <> ''R''
    AND dp.principal_id > 4
    AND dp.name NOT IN (''dbo'', ''guest'', ''INFORMATION_SCHEMA'', ''sys'');'

    EXEC sp_executesql @sql;

    FETCH NEXT FROM db_cursor INTO @dbname;
END

CLOSE db_cursor;
DEALLOCATE db_cursor;

-- Show results
-- SELECT * FROM #users ORDER BY dbname, dbusername;

-- Generate the SQL script to remove orphaned users
SELECT 'USE [' + dbname + ']; DROP USER [' + dbusername + '];' AS DropUserSQL
FROM #users
WHERE dbname NOT IN ('master', 'model', 'msdb', 'tempdb')
ORDER BY dbname, dbusername;

-- Cleanup
DROP TABLE #users;
DROP TABLE #userDatabases;
