#!/bin/bash

# Define debug mode (hardcoded)
DEBUG=0  # Set to 1 for debug mode, 0 for normal execution

# Check number of arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <primary_server> <database_name>"
    echo "Example: $0 SQLP5384 CRIMS"
    exit 1
fi

# Define variables from input parameters
PRI_MSSQL_SVRNAME="$1"
DBNAME="$2"

# Display input parameters
echo "Parameters:"
echo "Primary Server: ${PRI_MSSQL_SVRNAME}"
echo "Database Name: ${DBNAME}"
echo "Debug Mode: ${DEBUG}"
echo ""

# Check if sa_maint.pwd file exists and has content
if [ ! -s sa_maint.pwd ]; then
    echo "Error: Please put the sa_maint password into sa_maint.pwd file"
    exit 1
fi

# Create the SQL query
cat << EOF > checkSeeding.sql
SET NOCOUNT ON;
GO
SELECT
    das.start_time,
    das.completion_time,
    ag.name AS availability_group_name,
    dbcs.database_name,      -- NULL on failure
    ar.replica_server_name,  -- secondary
    das.is_source,           -- 0 = receiving (target)
    das.current_state,       -- COMPLETED or FAILED
    das.performed_seeding,   -- 1 = seeding actually run, 0 = it was skipped
    das.failure_state,
    das.failure_state_desc,
    das.error_code,
    das.number_of_attempts
FROM
    sys.dm_hadr_automatic_seeding AS das
LEFT JOIN
    sys.availability_groups AS ag ON das.ag_id = ag.group_id
LEFT JOIN
    sys.availability_databases_cluster AS dbcs ON das.ag_db_id = dbcs.group_database_id
LEFT JOIN
    sys.availability_replicas AS ar ON das.ag_remote_replica_id = ar.replica_id
WHERE dbcs.database_name = '${DBNAME}'
ORDER BY
    das.start_time DESC;
EOF

echo "Checking automatic seeding status for database ${DBNAME} on ${PRI_MSSQL_SVRNAME}..."
if [ ${DEBUG} -eq 0 ]; then
    sqlcmd -S${PRI_MSSQL_SVRNAME},2500 -U sa_maint -i checkSeeding.sql -w9999 -h -1 -W -P `cat sa_maint.pwd` | tee checkSeeding.out
else
    echo "DEBUG: Would execute this SQL query:"
    cat checkSeeding.sql
fi

# Cleanup only if not in debug mode
if [ ${DEBUG} -eq 0 ]; then
    rm checkSeeding.sql
    rm checkSeeding.out
fi

echo ""
echo "Query completed."
