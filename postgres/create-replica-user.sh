#!/bin/bash
# The SQL user is for replication purpose and not for admin. 

set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	CREATE ROLE replication WITH REPLICATION PASSWORD '$REPLICATION_PASSWORD' LOGIN
EOSQL