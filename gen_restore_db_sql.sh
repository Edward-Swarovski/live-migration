#!/bin/bash

# Check for correct number of arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <MSSQL_SERVERNAME> <DATABASE_NAME>"
    exit 1
fi

SERVERNAME="$1"
DBNAME="$2"
SQLFILE="${SERVERNAME}_${DBNAME}_dbrestore.sql"

# Check for sa_maint.pwd
if [ ! -s sa_maint.pwd ]; then
    echo "Error: Please create sa_maint.pwd with the sa_maint password."
    exit 1
fi

# Generate T-SQL script to output RESTORE DATABASE statement
cat << EOF > get_restore_sql.sql
DECLARE @DBNAME SYSNAME       = '${DBNAME}';
DECLARE @BackupPath NVARCHAR(4000), @Sep NVARCHAR(1);
DECLARE @BakFile NVARCHAR(4000), @MdfFile NVARCHAR(4000), @LdfFile NVARCHAR(4000);
DECLARE @LogicalDataName SYSNAME, @LogicalLogName SYSNAME;
DECLARE @RestoreSQL NVARCHAR(MAX);

EXEC master.dbo.xp_instance_regread
    N'HKEY_LOCAL_MACHINE',
    N'Software\Microsoft\MSSQLServer\MSSQLServer',
    N'BackupDirectory',
    @BackupPath OUTPUT;

SET @Sep = CASE 
             WHEN CHARINDEX(':', @BackupPath) > 0 THEN '\\'
             ELSE '/' 
           END;

-- Append BACKUPS folder for Windows-style path
IF CHARINDEX(':', @BackupPath) > 0
    SET @BackupPath = @BackupPath + @Sep + 'BACKUPS';

SELECT 
    @LogicalDataName = mf.name,
    @MdfFile         = mf.physical_name
FROM sys.master_files mf
WHERE mf.database_id = DB_ID(@DBNAME) AND mf.type_desc = 'ROWS';

SELECT 
    @LogicalLogName = mf.name,
    @LdfFile        = mf.physical_name
FROM sys.master_files mf
WHERE mf.database_id = DB_ID(@DBNAME) AND mf.type_desc = 'LOG';

SET @BakFile = @BackupPath + @Sep + @DBNAME + '.bak';

SET @RestoreSQL = '
use master
go
RESTORE DATABASE [' + @DBNAME + ']
FROM DISK = N''' + @BakFile + '''
WITH REPLACE,
     MOVE ''' + @LogicalDataName + ''' TO ''' + @MdfFile + ''',
     MOVE ''' + @LogicalLogName + ''' TO ''' + @LdfFile + ''',
     STATS = 5;
go
';

PRINT @RestoreSQL;
EOF

# Run sqlcmd to generate the restore SQL
sqlcmd -S${SERVERNAME},2500 -U sa_maint -i get_restore_sql.sql -h -1 -W -P "$(cat sa_maint.pwd)" > "${SQLFILE}"

echo "Generated restore SQL file: ${SQLFILE}"

# Cleanup
rm -f get_restore_sql.sql
