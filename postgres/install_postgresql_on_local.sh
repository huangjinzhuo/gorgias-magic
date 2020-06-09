# Install PostgreSQL on local machine (Ubuntu)

sudo su -

apt install PostgreSQL postgresql-contrib
# Now the database server can be started like this, but don't do it yet:
# /usr/lib/postgresql/10/bin/pg_ctl -D /var/lib/postgresql/10/main -l logfile start

# PostgreSQL can be started up upon server boot:
update-rc.d postgresql enable

# Start PostgreSQL
service postgresql start

# Login as postgres user. By default, user is postgres, and no password.
su - postgres 
# Connect to PostgreSQL
psql 
# Or connect from a remote place:
# psql -h hostname_of_sql_server -p 5432

# List databases in the Postgres server, then exit
\l
\q
