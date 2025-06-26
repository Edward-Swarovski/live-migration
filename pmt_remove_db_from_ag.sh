#!/bin/bash

# Define debug mode (hardcoded)
DEBUG=0  # Set to 1 for debug mode, 0 for normal execution

# Check number of arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <primary_server> <secondary_server> <database_name>"
    echo "Example: $0 SQLP5384 SQLP5385 CRIMS"
    exit 1
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
DROP AVAILABILITY GROUP [${DBNAME}_ag];
go
DROP database [${DBNAME}];
go
EOF

#SECONDARY: DROP AG
echo "Drop Availability Group in Secondary"
echo "Drop Database in Secondary"
echo "${SEC_MSSQL_SVRNAME}: Execute: DROP AVAILABILITY GROUP [${DBNAME}_ag];"
echo "${SEC_MSSQL_SVRNAME}: Execute: DROP database [${DBNAME}];"
if [ ${DEBUG} -eq 0 ]; then
    sqlcmd -S${SEC_MSSQL_SVRNAME},2500 -U sa_maint -i runIt.sql -w9999 -h -1 -W -P `cat sa_maint.pwd` | tee runIt.out
else
    echo "DEBUG: sqlcmd command would be executed here"
fi

if [ $? -ne 0 ]; then
    echo "Error: SQLCMD failed on server ${SEC_MSSQL_SVRNAME}.
    echo "Exit with Error..."
    exit 2
fi

cat << EOF > runIt.sql
ALTER AVAILABILITY GROUP [${DBNAME}_ag] REMOVE DATABASE [${DBNAME}];
EOF

#PRIMARY: ALTER AG
echo "Remove ${DBNAME} from Availability Group in Primary"
echo "${PRI_MSSQL_SVRNAME}: Execute: ALTER AVAILABILITY GROUP [${DBNAME}_ag] REMOVE [${DBNAME}];"
if [ ${DEBUG} -eq 0 ]; then
    sqlcmd -S${PRI_MSSQL_SVRNAME},2500 -U sa_maint -i runIt.sql -w9999 -h -1 -W -P `cat sa_maint.pwd` | tee runIt.out
else
    echo "DEBUG: sqlcmd command would be executed here"
fi

if [ $? -ne 0 ]; then
    echo "Error: SQLCMD failed on server ${PRI_MSSQL_SVRNAME}.
    echo "Exit with Error..."
    exit 2
fi

# Cleanup only if not in debug mode
if [ ${DEBUG} -eq 0 ]; then
    rm runIt.sql
    rm runIt.out
fi

echo ""
echo "Next Step:"
echo "  Perform Database Restore in Primary with Replace"
