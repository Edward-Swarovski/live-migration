#!/bin/bash

# Define server name variable
MSSQL_SVRNAME="SQLP5384"

# Check if sa_maint.pwd file exists and has content
if [ ! -s sa_maint.pwd ]; then
    echo "Error: Please put the sa_maint password into sa_maint.pwd file"
    exit 1
fi

echo "Starting database drop operations on server ${MSSQL_SVRNAME}..."

# Drop databases
echo "Dropping databases..."
cat << EOF > drop_pri_db_fr_ag.sql
ALTER AVAILABILITY GROUP CRIMS_ag REMOVE DATABASE [CRIMS];
ALTER AVAILABILITY GROUP ODS_ag REMOVE DATABASE [ODS];
ALTER AVAILABILITY GROUP thinkfolio_nomura_ag REMOVE DATABASE [thinkfolio_nomura];
ALTER AVAILABILITY GROUP thinktransfer_nomura_ag REMOVE DATABASE [thinktransfer_nomura];
EOF

sqlcmd -S${MSSQL_SVRNAME},2500 -U sa_maint -i drop_pri_db_fr_ag.sql -o ${MSSQL_SVRNAME}_remove_primary_db_from_ag.out -h -1 -W -P `cat sa_maint.pwd`

if [ $? -ne 0 ]; then
    echo "Error: SQLCMD failed on server ${MSSQL_SVRNAME}. Check the output file for details."
    exit 2
fi

# Cleanup
rm -f drop_pri_db_fr_ag.sql

echo "Database drop primary database from AG completed on server ${MSSQL_SVRNAME}."
echo "Check ${MSSQL_SVRNAME}_remove_primary_db_from_ag.out for results."
cat ${MSSQL_SVRNAME}_remove_primary_db_from_ag.out.out
