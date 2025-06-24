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

# Generate / Execute SQL to change schema ownership to DBO
echo "Changing schema ownership to DBO..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i gen_chg_schema_owner_to_dbo.sql -w9999 -o ${MSSQL_SVRNAME}_chg_schema_owner_to_dbo.sql -h -1 -W -P `cat sa_maint.pwd`
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i ${MSSQL_SVRNAME}_chg_schema_owner_to_dbo.sql -w9999 -o ${MSSQL_SVRNAME}_chg_schema_owner_to_dbo.out -h -1 -W -P `cat sa_maint.pwd`

# Generate / Execute SQL to remove orphan user [NT *****\ USER]
echo "Removing NT service DB users..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i gen_drop_nt_service_dbuser.sql -w9999 -o ${MSSQL_SVRNAME}_drop_nt_service_dbuser.sql -h -1 -W -P `cat sa_maint.pwd`
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i ${MSSQL_SVRNAME}_drop_nt_service_dbuser.sql -w9999 -o ${MSSQL_SVRNAME}_drop_nt_service_dbuser.out -h -1 -W -P `cat sa_maint.pwd`

# Generate / Execute SQL to remove orphan user
echo "Removing orphan DB users..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i gen_drop_orphan_dbuser.sql -w9999 -o ${MSSQL_SVRNAME}_drop_orphan_dbuser.sql -h -1 -W -P `cat sa_maint.pwd`
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i ${MSSQL_SVRNAME}_drop_orphan_dbuser.sql -w9999 -o ${MSSQL_SVRNAME}_drop_orphan_dbuser.out -h -1 -W -P `cat sa_maint.pwd`

echo "All operations completed on server ${MSSQL_SVRNAME}."
