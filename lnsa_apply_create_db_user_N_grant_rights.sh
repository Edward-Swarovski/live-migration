#!/bin/bash

# Login And Schema Adjustment
# MSSQL migration

# Check if server name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <MSSQL_SERVER_NAME>"
    exit 1
fi

# Assign server name from first argument
MSSQL_SVRNAME="$1"

# Check if sa_maint.pwd file exists and has content
if [ ! -s sa_maint.pwd ]; then
    echo "Error: Please put the sa_maint password into sa_maint.pwd file"
    exit 1
fi


echo "Starting SQL operations on server ${MSSQL_SVRNAME}..."

# Execute SQL to Create DB User captured in Pre-Migration Task
echo "Create DB Users..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i ${MSSQL_SVRNAME}_create_dbuser.sql -w9999 -o ${MSSQL_SVRNAME}_create_dbuser.out -h -1 -W -P `cat sa_maint.pwd`

# Execute SQL to alter DB roles add members which captured in Pre-Migration Task
echo "Alter DB role ... add members.."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i ${MSSQL_SVRNAME}_alter_role_membership.sql -w9999 -o ${MSSQL_SVRNAME}_alter_role_membership.out -h -1 -W -P `cat sa_maint.pwd`

# Execute SQL to grant permission to dbusers which captured in Pre-Migration Task
echo "Grant rights to dbuser ..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i ${MSSQL_SVRNAME}_grant_right_dbuser.sql -w9999 -o ${MSSQL_SVRNAME}_grant_right_dbuser.out -h -1 -W -P `cat sa_maint.pwd`

echo "All operations completed on server ${MSSQL_SVRNAME}."
