#!/bin/bash

# Define debug mode
DEBUG=0  # Set to 1 for debug mode, 0 for normal execution

# Check number of arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <primary_server> <secondary_server> <database_name>"
    echo "Example: $0 SQLP5384 SQLP5385 CRIMS"
    exit 1
fi

# Define server name variables from input parameters
PRI_MSSQL_SVRNAME="$1"
SEC_MSSQL_SVRNAME="$2"
DBNAME="$3"

# Display input parameters
echo "Parameters:"
echo "  Primary Server:   ${PRI_MSSQL_SVRNAME}"
echo "  Secondary Server: ${SEC_MSSQL_SVRNAME}"
echo "  Database Name:    ${DBNAME}"
echo "  Debug Mode:       ${DEBUG}"
echo ""

# Check if sa_maint.pwd file exists and has content
if [ ! -s sa_maint.pwd ]; then
    echo "Error: Please put the sa_maint password into sa_maint.pwd file"
    exit 1
fi

# Load password into variable
SQL_PWD=$(< sa_maint.pwd)

# Create SQL script for secondary: drop AG and DB
cat << EOF > runIt.sql
DROP AVAILABILITY GROUP [${DBNAME}_ag];
GO
DROP DATABASE [${DBNAME}];
GO
EOF

echo "[SECONDARY] Dropping Availability Group and Database..."
echo "${SEC_MSSQL_SVRNAME}: DROP AG [${DBNAME}_ag] and DROP DATABASE [${DBNAME}]"

if [ ${DEBUG} -eq 0 ]; then
    sqlcmd -S${SEC_MSSQL_SVRNAME},2500 -U sa_maint -i runIt.sql -w9999 -h -1 -W -P "$SQL_PWD" | tee runIt.out
    if [ $? -ne 0 ]; then
        echo "Error: SQLCMD failed on server ${SEC_MSSQL_SVRNAME}."
        echo "Exit with Error..."
        exit 2
    fi
else
    echo "DEBUG: Skipping sqlcmd execution on secondary."
fi

# Create SQL script for primary: remove DB from AG
cat << EOF > runIt.sql
ALTER AVAILABILITY GROUP [${DBNAME}_ag] REMOVE DATABASE [${DBNAME}];
EOF

echo "[PRIMARY] Removing ${DBNAME} from Availability Group..."
echo "${PRI_MSSQL_SVRNAME}: ALTER AG [${DBNAME}_ag] REMOVE DATABASE [${DBNAME}]"

if [ ${DEBUG} -eq 0 ]; then
    sqlcmd -S${PRI_MSSQL_SVRNAME},2500 -U sa_maint -i runIt.sql -w9999 -h -1 -W -P "$SQL_PWD" | tee runIt.out
    if [ $? -ne 0 ]; then
        echo "Error: SQLCMD failed on server ${PRI_MSSQL_SVRNAME}."
        echo "Exit with Error..."
        exit 2
    fi
else
    echo "DEBUG: Skipping sqlcmd execution on primary."
fi

# Cleanup
if [ ${DEBUG} -eq 0 ]; then
    rm -f runIt.sql runIt.out
fi

echo ""
echo "Next Step:"
echo "  Perform Database Restore in Primary with REPLACE option."
