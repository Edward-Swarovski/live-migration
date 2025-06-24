#!/bin/bash

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

# Generate SQL to change database file autogrowth
echo "Generate Alter database autogrowh statements..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i gen_alter_db_autogrowth.sql -w9999 -o ${MSSQL_SVRNAME}_alter_db_autogrowth.sql -h -1 -W -P `cat sa_maint.pwd`

# Generate CREATE USER statement
echo "Generating CREATE USER statements..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i gen_create_dbuser.sql -w9999 -o ${MSSQL_SVRNAME}_create_dbuser.sql -h -1 -W -P `cat sa_maint.pwd`

# Generate ALTER ROLE statement
echo "Generating ALTER ROLE statements..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i gen_alter_db_role_membership.sql -w9999 -o ${MSSQL_SVRNAME}_alter_db_role_membership.sql -h -1 -W -P `cat sa_maint.pwd`

# Generate GRANT statement
echo "Generating GRANT statements..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i gen_grant_right_dbuser.sql -w9999 -o ${MSSQL_SVRNAME}_grant_right_dbuser.sql -h -1 -W -P `cat sa_maint.pwd`

# Generate ALTER DATABASE statement
echo "Generating ALTER DATABASE statements..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i gen_alter_db_autogrowth.sql -w9999 -o ${MSSQL_SVRNAME}_alter_db_autogrowth.sql -h -1 -W -P `cat sa_maint.pwd`

# Generate DROP LOGIN and CREATE LOGIN statement
echo "Generating DROP/CREATE LOGIN statements..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i gen_drop_n_create_app_login.sql -o ${MSSQL_SVRNAME}_drop_n_create_app_login.sql -h -1 -y999 -P `cat sa_maint.pwd`

# Generate GRANT, REVOKE, DENY statements
echo "Generating GRANT/REVOKE/DENY statements..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i gen_grant_revoke_deny.sql -o ${MSSQL_SVRNAME}_grant_revoke_deny.sql -h -1 -W -P `cat sa_maint.pwd`

# Generate SERVER ROLES MEMBERSHIP statements
echo "Generating SERVER ROLES MEMBERSHIP statements..."
sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i gen_srv_roles_membership.sql -o ${MSSQL_SVRNAME}_srv_roles_membership.sql -h -1 -W -P `cat sa_maint.pwd`

echo "All operations completed on server ${MSSQL_SVRNAME}."
