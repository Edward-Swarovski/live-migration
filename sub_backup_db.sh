#!/bin/bash

# Define debug mode (hardcoded)
DEBUG=0  # Set to 1 for debug mode, 0 for normal execution

# Check number of arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <server_name> <database_name>"
    echo "Example: $0 SQLP5384 CRIMS"
    exit 1
fi

# Define variables from input parameters
MSSQL_SVRNAME="$1"
DBNAME="$2"

# Display input parameters
echo "Parameters:"
echo "Server: ${MSSQL_SVRNAME}"
echo "Database Name: ${DBNAME}"
echo "Debug Mode: ${DEBUG}"
echo ""

# Check if sa_maint.pwd file exists and has content
if [ ! -s sa_maint.pwd ]; then
    echo "Error: Please put the sa_maint password into sa_maint.pwd file"
    exit 1
fi

# First, get the default backup location
cat << EOF > getBackupPath.sql
SET NOCOUNT ON;
GO
EXEC master.dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer',N'BackupDirectory'
EOF

echo "Getting default backup location..."
if [ ${DEBUG} -eq 0 ]; then
    # Get the last line and extract everything after the last space
    BACKUP_PATH=$(sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i getBackupPath.sql -h -1 -W -P `cat sa_maint.pwd` | tail -n 1 | awk '{print $NF}')
    echo "Raw backup location: ${BACKUP_PATH}"

    # Check if it's a Windows path (starts with a drive letter followed by :)
    if [[ $BACKUP_PATH =~ ^[A-Za-z]: ]]; then
        echo "Detected Windows path"
        # For Windows, append \backups to the path
        BACKUP_PATH="${BACKUP_PATH}\\backups"
        # Create the backup SQL with Windows path format
        cat << EOF > runIt.sql
BACKUP DATABASE [${DBNAME}] to disk = N'${BACKUP_PATH}\\${DBNAME}_AGSETUPBKP.bak' WITH STATS = 5;
EOF
    else
        echo "Detected Linux path"
        # For Linux, the path already includes /backups
        cat << EOF > runIt.sql
BACKUP DATABASE [${DBNAME}] to disk = N'${BACKUP_PATH}/${DBNAME}_AGSETUPBKP.bak' WITH STATS = 5;
EOF
    fi
else
    echo "DEBUG: Would get backup location from SQL Server"
    BACKUP_PATH="/local/mssql/MSSQLSERVER/dumps/backups"
    cat << EOF > runIt.sql
BACKUP DATABASE [${DBNAME}] to disk = N'${BACKUP_PATH}/${DBNAME}/${DBNAME}_AGSETUPBKP.bak';
EOF
fi

echo "Final backup location: ${BACKUP_PATH}"
echo "Executing SQL:"
cat runIt.sql

echo "${MSSQL_SVRNAME}: Executing backup..."
if [ ${DEBUG} -eq 0 ]; then
    sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i runIt.sql -w9999 -h -1 -W -P `cat sa_maint.pwd` | tee runIt.out
else
    echo "DEBUG: sqlcmd command would be executed here"
fi

# Cleanup only if not in debug mode
if [ ${DEBUG} -eq 0 ]; then
    rm getBackupPath.sql
    rm runIt.sql
    rm runIt.out
fi

echo "Backup completed for database ${DBNAME}."
