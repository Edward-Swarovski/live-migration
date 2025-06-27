#!/bin/bash

# Check for required argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <MSSQL_SERVERNAME>"
    echo "Example: $0 SQLP5384"
    exit 1
fi

# Get server name
SERVERNAME="$1"
SQLFILE="${SERVERNAME}_alter_db_autogrowth.sql"
OUTFILE="${SERVERNAME}_alter_db_autogrowth.out"

# Check for sa_maint.pwd
if [ ! -s sa_maint.pwd ]; then
    echo "Error: Please put the sa_maint password into sa_maint.pwd file"
    exit 1
fi

# Check for SQL input file
if [ ! -f "$SQLFILE" ]; then
    echo "Error: SQL input file '$SQLFILE' not found."
    exit 1
fi

# Load password
SQL_PWD=$(< sa_maint.pwd)

# Run sqlcmd
echo "Executing $SQLFILE on server $SERVERNAME..."
sqlcmd -S${SERVERNAME},2500 -U sa_maint -i "$SQLFILE" -w9999 -h -1 -W -P "$SQL_PWD" | tee "$OUTFILE"
