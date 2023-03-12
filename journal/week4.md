# Week 4 — Postgres and RDS

### Created Postgres RDS on AWS and locally
- Used this command to spin up my AWS postgres RDS
```shell
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version 14.6 \
  --master-username root \
  --master-user-password *** \
  --allocated-storage 20 \
  --availability-zone eu-south-1a \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```
- Used one of these command to create a local Database named cruddur inside postgres locally
```sh
createdb cruddur -h localhost -U postgres

### OR ###

psql -U postgres -h localhost
# enter the password (password)
\l # list all databases 
DROP database cruddur; # drop cruddur db if it exist.
CREATE database cruddur; # NOW, create the new cruddur db.
```

### Add UUID Extension
- Created a new SQL file called `schema.sql` and placed it in `backend-flask/db`
- Postgres will generate out UUIDs. We'll need to use an extension called "uuid-ossp" inside `schema.sql` file
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
- The benefit of using Unique IDs is that to hide number of customers for competitors.
- Import `schema.sql` file into our database and run it
```sh
psql cruddur < db/schema.sql -h localhost -U postgres
```

### Connection URL String
Connection URL String: a way of providing all of the details to authenticate to DB server
```sh
export CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"
gp env CONNECTION_URL="postgresql://postgres:password@localhost:5432/cruddur"

export PROD_CONNECTION_URL="postgresql://root:***@cruddur-db-instance.cw13efqq4djw.eu-south-1.rds.amazonaws.com:5432/cruddur"
gp env PROD_CONNECTION_URL="postgresql://postgres::***@cruddur-db-instance.cw13efqq4djw.eu-south-1.rds.amazonaws.com:5432/cruddur"
```
- To try the authenticating with local DB
```sh
psql CONNECTION_URL
# The output (which means you're in).
cruddur=#
```

## Use Bash Scripts
- Reason for using Bash Scripts: we will use schema file often, So we will be able to turn down the database, set up the database, load the schema.
- Created three scripts `db-create`, `db-drop`, `db-schema-load`
- Give the scipts the required permissions `rwxr--r--`
```sh
chmod 744 db-create db-drop db-schema-load
```

#### `db-drop`
```sh
#! /usr/bin/bash
### coloring
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-drop"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "drop database cruddur;"
```
- we are using `sed` to replace `/cruddur` with nothing (remove it); -> because we can't drop the database while we're connecting to it.
- we used a backslash `\` to escape the next forward slash `/`

