#!/bin/bash

# Define debug mode (hardcoded)
DEBUG=0  # Set to 1 for debug mode, 0 for normal execution

# Check number of arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <primary_server> <secondary_server> <database_name>"
    echo "Example: $0 SQLP5384 SQLP5385 CRIMS"
    exit 1
fi

cat << EOF > runIt.sql
DROP AVAILABILITY GROUP [${DBNAME}_ag];
go
DROP database [${DBNAME}];
go
EOF

#SECONDARY: DROP AG
echo "${SEC_MSSQL_SVRNAME}: Execute: DROP AVAILABILITY GROUP [${DBNAME}_ag];"
echo "${SEC_MSSQL_SVRNAME}: Execute: DROP database [${DBNAME}];"
if [ ${DEBUG} -eq 0 ]; then
    sqlcmd -S${SEC_MSSQL_SVRNAME},2500 -U sa_maint -i runIt.sql -w9999 -h -1 -W -P `cat sa_maint.pwd` | tee runIt.out
else
    echo "DEBUG: sqlcmd command would be executed here"
fi


# Define server name variable from input parameters
PRI_MSSQL_SVRNAME="$1"
SEC_MSSQL_SVRNAME="$2"
DBNAME="$3"

# Display input parameters
echo "Parameters:"
echo "Primary Server: ${PRI_MSSQL_SVRNAME}"
echo "Secondary Server: ${SEC_MSSQL_SVRNAME}"
echo "Database Name: ${DBNAME}"
echo "Debug Mode: ${DEBUG}"
echo ""

# Check if sa_maint.pwd file exists and has content
if [ ! -s sa_maint.pwd ]; then
    echo "Error: Please put the sa_maint password into sa_maint.pwd file"
    exit 1
fi

cat << EOF > runIt.sql
ALTER AVAILABILITY GROUP [${DBNAME}_ag] GRANT CREATE ANY DATABASE;
EOF

#PRIMARY: ALTER AG
echo "${PRI_MSSQL_SVRNAME}: Execute: ALTER AVAILABILITY GROUP [${DBNAME}_ag] GRANT CREATE ANY DATABASE;"
if [ ${DEBUG} -eq 0 ]; then
    sqlcmd -S${PRI_MSSQL_SVRNAME},2500 -U sa_maint -i runIt.sql -w9999 -h -1 -W -P `cat sa_maint.pwd` | tee runIt.out
else
    echo "DEBUG: sqlcmd command would be executed here"
fi

#SECONDARY: ALTER AG with 10 seconds delay to allow full AG sync
echo "${SEC_MSSQL_SVRNAME}: Sleeping 10 seconds before GRANT CREATE ANY DATABASE on secondary..."
sleep 10

cat << EOF > runIt.sql
ALTER AVAILABILITY GROUP [${DBNAME}_ag] JOIN WITH (CLUSTER_TYPE = NONE);
go
ALTER AVAILABILITY GROUP [${DBNAME}_ag] GRANT CREATE ANY DATABASE;
go
EOF

#SECONDARY: ALTER AG
echo "${SEC_MSSQL_SVRNAME}: Execute: ALTER AVAILABILITY GROUP [${DBNAME}_ag] JOIN WITH (CLUSTER_TYPE = NONE);"
echo "${SEC_MSSQL_SVRNAME}: Execute: ALTER AVAILABILITY GROUP [${DBNAME}_ag] GRANT CREATE ANY DATABASE;"
if [ ${DEBUG} -eq 0 ]; then
    sqlcmd -S${SEC_MSSQL_SVRNAME},2500 -U sa_maint -i runIt.sql -w9999 -h -1 -W -P `cat sa_maint.pwd` | tee runIt.out
else
    echo "DEBUG: sqlcmd command would be executed here"
fi

cat << EOF > runIt.sql
ALTER DATABASE [${DBNAME}] SET RECOVERY FULL WITH NO_WAIT;
EOF
#PRIMARY: ALTER DATABASE
echo "${PRI_MSSQL_SVRNAME}: Execute: ALTER DATABASE [${DBNAME}] SET RECOVERY FULL WITH NO_WAIT;"
if [ ${DEBUG} -eq 0 ]; then
    sqlcmd -S${PRI_MSSQL_SVRNAME},2500 -U sa_maint -i runIt.sql -w9999 -h -1 -W -P `cat sa_maint.pwd` | tee runIt.out
else
    echo "DEBUG: sqlcmd command would be executed here"
fi

#PRIMARY: BACKUP DATABASE
echo "BACKUP DATABASE ${PRI_MSSQL_SVRNAME}.${DBNAME}"
if [ ${DEBUG} -eq 0 ]; then
    ./agrj_backup_db.sh ${PRI_MSSQL_SVRNAME} ${DBNAME}
else
    echo "DEBUG: agrj_backup_db.sh  ${PRI_MSSQL_SVRNAME} ${DBNAME} would be executed here"
fi

cat << EOF > runIt.sql
ALTER AVAILABILITY GROUP [${DBNAME}_ag] ADD DATABASE [${DBNAME}];
EOF
echo "${PRI_MSSQL_SVRNAME}: Execute: ALTER AVAILABILITY GROUP [${DBNAME}_ag] ADD DATABASE [${DBNAME}];"
if [ ${DEBUG} -eq 0 ]; then
    sqlcmd -S${PRI_MSSQL_SVRNAME},2500 -U sa_maint -i runIt.sql -w9999 -h -1 -W -P `cat sa_maint.pwd` | tee runIt.out
else
    echo "DEBUG: sqlcmd command would be executed here"
fi

# Cleanup only if not in debug mode
if [ ${DEBUG} -eq 0 ]; then
    rm runIt.sql
    rm runIt.out
fi

echo "All AG setup completed on database ${DBNAME}."
echo ""
echo "Run the below command to check the AG Autoseeding status"
echo ""
echo "  ./agrj_chk_autoseeding_status.sh ${PRI_MSSQL_SVRNAME} ${DBNAME}"
