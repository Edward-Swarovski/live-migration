#!/bin/bash

# Check for correct number of arguments
if [ $# -ne 2 ]; then
    echo "Usage: $0 <server_name> <database_name>"
    echo "Example: $0 SQLP5384 CRIMS"
    exit 1
fi

# Input parameters
SERVERNAME="$1"
DBNAME="$2"
SQLFILE="${SERVERNAME}_${DBNAME}.sql"

# Check if sa_maint.pwd exists
if [ ! -s sa_maint.pwd ]; then
    echo "Error: Please put the sa_maint password into sa_maint.pwd file"
    exit 1
fi

# Check if the SQL file exists
if [ ! -f "$SQLFILE" ]; then
    echo "Error: SQL file '$SQLFILE' not found."
    exit 1
fi

# Load password
SQL_PWD=$(< sa_maint.pwd)

# Run sqlcmd and tee output to terminal
echo "Running SQL script ${SQLFILE} on server ${SERVERNAME}..."
sqlcmd -S${SERVERNAME},2500 -U sa_maint -i "$SQLFILE" -w9999 -h -1 -W -P "$SQL_PWD" | tee "${SERVERNAME}_${DBNAME}.out"
