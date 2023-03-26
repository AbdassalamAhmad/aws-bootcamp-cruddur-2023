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
psql $CONNECTION_URL
# The output (which means you're in).
cruddur=#
```

## Use Bash Scripts
- Reason for using Bash Scripts: we will use schema file often, So we will be able to turn down the database, set up the database, load the schema.
- Created these scripts `db-create`, `db-drop`, `db-schema-load`, `db-connect`, `db-seed`, `db-sessions`, `db-setup`.
- Give the scipts the required permissions `rwxr--r--`
```sh
chmod 744 db-create db-drop db-schema-load db-connect db-seed db-sessions db-setup
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

#### `db-create`
- To create a database.
#### `db-schema-load`
- To load the schema script.
#### `db-connect`
- To connect to the database.
#### `db-seed`
- To fill the database with some mock data to try some commands on the database.
#### `db-sessions`
- To see what connections are open, the postgreSQL extention we use seems to make the connection up and doesn't close them.
#### `db-setup`
- To run all of the scripts.

> See [this commit](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/4e7d426b7e3fd2b70088cef6654fdddf1bc471c5) for more details on the scripts.

### Create Tables Inside Cruddur Database
- public is schema or namespace which comes with any database by default.
- we will be using different schemas like public,..etc when having multiple subdomains and each one will connect to one schema. (OR Databse per Domain i'm not sure yet)
```sql
CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text,
  handle text,
  cognito_user_id text,
  created_at TIMESTAMP default current_timestamp NOT NULL
);

CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```
- The meaning of `uuid` inside `public.activities` table is a unique id for each activity.
- The meaning of `user_uuid` inside `public.activities` table is the user unique id who did that activity.

### Seed Data into our Databse
```sql
INSERT INTO public.users (display_name, handle, cognito_user_id)
VALUES
  ('Andrew Brown', 'andrewbrown' ,'MOCK'),
  ('Andrew Bayko', 'bayko' ,'MOCK');

INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES
  (
    (SELECT uuid from public.users WHERE users.handle = 'andrewbrown' LIMIT 1),
    'This was imported as seed data!',
    current_timestamp + interval '10 day'
  )
```

## SQL Commands
- First, connect to our databse using `db-connect` script.
```sql
-- This command will display data correctly in "Expand Mode"
\x auto 
-- will show all of the activities we put using seed script.
SELECT * FROM activities;
```

### SQL Driver Psycopg (V3)
- This driver will enable us to use python script to run SQL commands of our DB.
- Install the driver using `pip` by adding it to `requirementes.txt`
```txt
psycopg[binary]
psycopg[pool]
```
- The benefit of using connection pooling is to reuse some connection from finished users to current users.
- **NOTE:** we will be using raw SQL commands because it is a lot faster check [this_time](https://youtu.be/Sa2iB33sKFo?list=PLBfufR7vyJJ7k25byhRXJldB5AiwgNnWv&t=2064)

- Add this code to `lib/db.py`
```py
from psycopg_pool import ConnectionPool
# ....

def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql
# ....
```
- The previous function will do the following:
  - {template} will have SQL Command (statement)
  - convert every row from SQL to json then we put it in array then we put that array into json again.
  - `'[]'::json` will return empty json if previous return empty.
  - here is the tuble we get back from `print (json)`
    ```json
    ([{'uuid': '93a4b885-e070-4454-802e-d4a76bb0b6db', 'user_uuid': '041baa78-3ebb-44c9-b9c8-b99df06faba2', 'message': 'This was imported as seed data!', 'replies_count': 0, 'reposts_count': 0, 'likes_count': 0, 'reply_to_activity_uuid': None, 'expires_at': '2023-03-26T04:42:45.500728', 'created_at': '2023-03-16T04:42:45.500728'}],)
    ```
  - As you say the first part of the tuble is what we want because the second one is empty so we `return json[0]`
 
## Connect to Production RDS
- Start RDS.
- Edit `db-connect` script to accept prod RDS Connect URL.
- Edit security group to accept traffic comming from gitpod ID.
- Used this command to modify our IP inside SG because everytime we lunch gitpod, its IP will change.
```sh
export DB_SG_ID="sg-03612a80ef9ea9c32"
gp env DB_SG_ID="sg-03612a80ef9ea9c32"
export DB_SG_RULE_ID="sgr-000875ae83d6cc004"
gp env DB_SG_RULE_ID="sgr-000875ae83d6cc004"
```
- Put this command in `rds-update-sg-rule` script.
```sh
aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules "SecurityGroupRuleId=$DB_SG_RULE_ID,SecurityGroupRule={Description=gitpod_from_command,IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32}"
```
- Add this code to `.gitpod.yml` under postgres to extract the new IP everytime we open a workspace and put it inside `rds-update-sg-rule` script.
```yml
      # Get the IP of GITPOD and put it inside `rds-update-sg-rule` script
      gp sync-await aws-cli
      export GITPOD_IP=$(curl ifconfig.me)
      source "$THEIA_WORKSPACE_ROOT/backend-flask/bin/rds-update-sg-rule"
```
- Change compose Connection URL
```yml
      CONNECTION_URL: "$PROD_CONNECTION_URL"
```
- Load the schema into our production RDS.
```sh
./backend-flask/bin/db-schema-load prod
```

## Create a Lambda Function 
- Function Name: cruddur-post-confirmation
- Runtime: Python 3.8
- Architecture: x86_64
- Enable VPC: 2 subnets, SG allows 5432 and ALL (default SG).

### Lambda Function Inside Configuration
- Created [cruddur-post-confirmation.py](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/aws/lambdas/cruddur-post-confirmation.py) which has our lambda code.
- Configure ENV Vars `CONNECTION_URL: postgresql://root:****@cruddur-db-instance.cw13efqq4djw.eu-south-1.rds.amazonaws.com:5432/cruddur`
- Added Lambda Layer (additional code) using this ARN `arn:aws:lambda:eu-south-1:898466741470:layer:psycopg2-py38:1`, check out [this repo](https://github.com/omenking/aws-bootcamp-cruddur-2023/blob/week-4/journal/week4.md#development) for more details.

- Added Lambda Trigger from cognito (user pool properties)
- Choose sign-up Trigger type then choose Post confirmation trigger then Assign OUR Lambda function.

- Edit `schema.sql` to include email and changed handle to preferred_username.
```sql
CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text NOT NULL,
  --handle text NOT NULL, handle is same as preferred_username
  preferred_username text NOT NULL, -- same as handle, make sure to check lambda function
  email text NOT NULL,
  cognito_user_id text NOT NULL,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```
- Run `db-schema-load` bash script to load the schema into our RDS.
#### proof of Lambda works after signing up and checking rds DB.
![image](https://user-images.githubusercontent.com/83673888/226085967-ebf5b614-0511-48f0-9f46-aac5ff7bd3df.png)


## Implement Create Activity && Link it with RDS
### Edit Lambda Code to Prevent SQL Injections && More Readable.

> [Commit Details](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/65db74bcfe3ff0cac181b5d13851c7565eaf7346)

### **Issue Solved** user handle was hard-coded
**Solution:**
- removed the hard coded value and replace it with `request.json["user_handle"]`
```py
# app.py
def data_activities():
  ######user_handle  = 'andrewbrown'######
  user_handle = request.json["user_handle"]
  message = request.json['message']
  ttl = request.json['ttl']
```
- added `user_handle={user}` so that it could be passed to `components/ActivityForm.js` 
```js
// pages/HomeFeedPage.js
        <ActivityForm  
          user_handle={user}
          popped={popped}
          setPopped={setPopped} 
          setActivities={setActivities} 
```
- add `user_handle` that gets its value from the above code.
```js
// components/ActivityForm.js
        body: JSON.stringify({
          user_handle: props.user_handle.handle,
          message: message,
          ttl: ttl
        }),
```

### Create a Folder that has SQL Code Separately to be Referenced in `db.py`, `create_activity.py`, `home_activities.py`
- `create.sql`:  will create the SQL ENTRY that has these values `user_uuid, message, expires_at` into our DB once `crud` button is pressed.
```sql
-- create.sql
INSERT INTO public.activities (user_uuid, message, expires_at)
VALUES (
  (SELECT uuid 
    FROM public.users 
    WHERE users.handle = %(handle)s
    LIMIT 1
  ), %(message)s, %(expires_at)s
) 
RETURNING uuid;
```
- **`home.sql`**: will GET the `activities` table and join it with `users` table to get `handle` and `display_name` columns `ON` condidtion of using the same user UUID column.
```sql
SELECT
  activities.uuid, users.display_name, users.handle, activities.message, activities.replies_count,
  activities.reposts_count, activities.likes_count, activities.reply_to_activity_uuid,
  activities.expires_at, activities.created_at
FROM public.activities
LEFT JOIN public.users ON users.uuid = activities.user_uuid
ORDER BY activities.created_at DESC
```

- **`create.sql`**: will create the activity and return its uuid which is unique per activity, to be passed to `CreateActivity.query_object_activity(uuid)` to get the object that will be displayed in json format (handled by front-end).
```sql
INSERT INTO public.activities (
  user_uuid, message, expires_at)
VALUES (
  (SELECT uuid FROM public.users WHERE users.handle = %(handle)s LIMIT 1),
  %(message)s, %(expires_at)s
) 
RETURNING uuid;
```

- **`object.sql`**: to convert sql to json BY getting the uuid from `CreateActivity.create_activity(user_handle,message,expires_at)` and passing it to `CreateActivity.query_object_activity(uuid)` so that it can be passed to front-end as json to be displayed.
```sql
SELECT
  activities.uuid, users.display_name, users.handle, 
  activities.message, activities.created_at, activities.expires_at
FROM public.activities
INNER JOIN public.users ON users.uuid = activities.user_uuid 
WHERE activities.uuid = %(uuid)s
```

## Workflow of **Creating an Activity**:
- Create an activity from UI.
![image](https://user-images.githubusercontent.com/83673888/227766102-0068027e-466c-4efb-ba5b-322381ab9e75.png)
- POST the content of `user_handle`, `message`, `ttl` to backend.
![image](https://user-images.githubusercontent.com/83673888/227766165-081bcb98-34c5-4bc1-9d74-ed0be6ae15cb.png)
- Pass the above values we get from front-end to `CreateActivity.run` function.
![image](https://user-images.githubusercontent.com/83673888/227766287-1eecb6b2-f34a-4db4-bb76-d6c6bdd9a2cd.png)
- Here are the steps that will get executed in order.
- <kbd>1</kbd> `run` will call two functions <kbd>2</kbd> `CreateActivity.createactivity` and <kbd>3</kbd> `CreateActivity.query_object_activity`
![image](https://user-images.githubusercontent.com/83673888/227766645-817ee81a-e1ff-4d95-9327-26fe39e010f5.png)
- Inside <kbd>2</kbd> we have <kbd>2-1</kbd> `db.template` that will get `create.sql`.
![image](https://user-images.githubusercontent.com/83673888/227766713-f212835e-9e9e-43c6-916c-2c039d516157.png)
![image](https://user-images.githubusercontent.com/83673888/227766754-f2554fb1-9f5d-42f5-a9cb-8e7566ea2b67.png)
- Once we have our sql we will execute <kbd>2-2</kbd> `db.query_commit` which will commit our activity to our RDS prod database.
- `db.query_commit` will return `returning_id` which is `uuid` of the activity.
- This `uuid` will be used on <kbd>3</kbd> `CreateActivity.query_object_activity(uuid)` to get a json object instead of an array.
![image](https://user-images.githubusercontent.com/83673888/227766840-e8f3f44b-5a01-499a-83df-bcb8fb8b73aa.png)
- <kbd>3-1</kbd> `object.sql` will get **the actual activity that will be shown at the end** in array format.
![image](https://user-images.githubusercontent.com/83673888/227767411-5e3fdd97-4d77-4e8f-bd48-a96d11ec1165.png)
- <kbd>3-2-1</kbd> `query_wrap_object` will wrap the array so that when it is commited in <kbd>3-2</kbd> it will have a json format
![image](https://user-images.githubusercontent.com/83673888/227767104-99b2051b-1022-4877-be24-f22efa3dd746.png)
- <kbd>3-2</kbd> `query_object_json` will get the wrapped sql and connect to our RDS and excute the SQL command.
- You can see the output of the SQL After executing it in the next picture.
![image](https://user-images.githubusercontent.com/83673888/227767029-380be240-67a5-4c85-ba5d-165f4044b1dc.png)


![image](https://user-images.githubusercontent.com/83673888/227767186-cb8b08e7-fd28-4c0c-a8d7-4da9b6a524c6.png)
![image](https://user-images.githubusercontent.com/83673888/227767219-8ae67775-03af-4eab-8fa4-70143b7dc2dd.png)
![image](https://user-images.githubusercontent.com/83673888/227767274-1f45fde1-5f6e-42dc-a37b-6ec4043ad172.png)


## Workflow of **Showing The Activity**:
![image](https://user-images.githubusercontent.com/83673888/227767820-be347092-b638-48fd-abf0-4869890023ee.png)
![image](https://user-images.githubusercontent.com/83673888/227767633-fa679f3f-d7a3-4035-88ab-5dd4fc26c336.png)
![image](https://user-images.githubusercontent.com/83673888/227767666-e19b32a6-8695-4304-8891-a167e7a8ceb0.png)
![image](https://user-images.githubusercontent.com/83673888/227767784-41a4dda4-cb3d-49f5-a56e-34818c885d0b.png)
![image](https://user-images.githubusercontent.com/83673888/227767913-c63fcd30-3679-487f-a60b-84aba5f383f7.png)







 
