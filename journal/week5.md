# Week 5 — DynamoDB and Serverless Caching

## Reconstruct Our `bin` Dir
```sh
├───bin
│   ├───db
│   │       connect
│   │       create
│   │       drop
│   │       schema-load
│   │       seed
│   │       sessions
│   │       setup
│   │
│   ├───ddb
│   │   │   delete
│   │   │   list-tables
│   │   │   scan
│   │   │   schema-load
│   │   │   seed
│   │   │
│   │   └───patterns
│   │           get-conversation
│   │           list-conversations
│   │
│   └───rds
│           update-sg-rule
```
- Update the parent path of these scripts `schema-load`, `seed`, `sessions`, `setup`
- Update `.gitpod.yml` file to fix SG of RDS
```yml
source "$THEIA_WORKSPACE_ROOT/backend-flask/bin/rds/update-sg-rule"
```
- Add boto3 library to `requirements.txt`
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/9bbb38177779dbfa1a6a7293b5c7d7bee73058f2)

## Add DynamoDB Scripts
- Add `schema-load`, `list-tables`, `delete` scripts.
### `schema-load`
- Create table in prod or locally based on `prod` paramater given while running the script.
### `list-tables`
- List tables in your AWS account or locally.
### `delete`
- Delete a specific table you give on running the script like `cruddur-messages`.
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/a2799a8777c8cefb19de439b24146bd6837d85e2)

## Fix issue with PROD_CONNECTION_URL
- When getting The connection url from front-end UI , it goes to backend and get the env from gitpod
which has the value of the PROD_CONNECTION_URL.
But when running `seed` script locally, the CONNECTION_URL that get passed is from terminal which has local postgres connection not the production one.

**SOLVING The Problem**
- make The connection url PROD_CONNECTION_URL inside docker-compose instead of CONNECTION_URL so that it will be the same value for both Front-end & Back-end AND week-5 python files. like `seed`
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/a278a6ff6ec7564b9043efa30ba0b5f50cafe3c9)

## Add More DynamoDB Scripts
### `seed`
- Fill tables with messages from andrew and bayko

- we designed our table to have two main values in pk (partition key) 
1. GRP = group of messages for a user (list of conversations)
```python
def create_message_group(client,message_group_uuid, my_user_uuid, last_message_at=None, message=None, other_user_uuid=None, other_user_display_name=None, other_user_handle=None):
  table_name = 'cruddur-messages'
  record = {
    'pk':   {'S': f"GRP#{my_user_uuid}"},
    'sk':   {'S': last_message_at},
    'message_group_uuid': {'S': message_group_uuid},
    'message':  {'S': message},
    'user_uuid': {'S': other_user_uuid},
    'user_display_name': {'S': other_user_display_name},
    'user_handle': {'S': other_user_handle}
  }

  response = client.put_item(
    TableName=table_name,
    Item=record
  )
```
2. MSG = single message of a specific message group (one content of a message inside one conversation)
```python 
def create_message(client,message_group_uuid, created_at, message, my_user_uuid, my_user_display_name, my_user_handle):
  table_name = 'cruddur-messages'
  record = {
    'pk':   {'S': f"MSG#{message_group_uuid}"},
    'sk':   {'S': created_at },
    'message_uuid': { 'S': str(uuid.uuid4()) },
    'message': {'S': message},
    'user_uuid': {'S': my_user_uuid},
    'user_display_name': {'S': my_user_display_name},
    'user_handle': {'S': my_user_handle}
  }
  # insert the record into the table
  response = client.put_item(
    TableName=table_name,
    Item=record
  )
```
### `scan`
- Get all of the items (rows) of the dynamodb table. (pretty expensive).

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/60926d48f90a4e4077bfd1c201d492a492a2b59b)

## Query one Value from our RDS
### `backend-flask/lib/db.py`
```python
  def query_value(self,sql,params={}):
    self.print_sql('value',sql,params)
    with self.pool.connection() as conn:
      with conn.cursor() as cur:
        cur.execute(sql,params)
        json = cur.fetchone()
        return json[0]
```
- That Query will be used in `backend-flask/bin/ddb/patterns/list-conversations` 
```python
def get_my_user_uuid():
  sql = """
    SELECT 
      users.uuid
    FROM users
    WHERE
      users.handle =%(handle)s
  """
  uuid = db.query_value(sql,{
    'handle':  'andrewbrown'
  })
  return uuid
```

## Implement Show Content of Conversation && List all the Conversations
### `list-conversations`
- Get list of all the messages that a specific user has made.

### `get-conversation`
- Show the actual messages of a specific conversation of my user ordered from the oldest to the newest (showing latest at the end).
- Limit the shown messages to 20.
- Filter the output query to a specific year OR a duration of specific time (month, week,..etc)

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/c3e6ffff2e0e41f1e8e490e0c1e8416dba3caf07)

## Create a script `backend-flask/bin/db/update_cognito_user_ids` to update cognito user id in our db
### ADD Env Variable
- This env var will be used in `backend-flask/bin/cognito/list-users`
```bash
export AWS_COGNITO_USER_POOL_ID="****"
gp env AWS_COGNITO_USER_POOL_ID="***"
```
- The idea behind `backend-flask/bin/cognito/list-users` and `backend-flask/bin/db/update_cognito_user_ids` is to fill cognito user id for the users in our database that are (hard-coded and seeded into the DB).<br>
- I think that this script is useless **for production usecase**, because once we create a user from UI, a lambda will be triggered and will update our database with cognito new users.
- We will need it for local development only to grap cognito user id instead of hard-coding it.
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/10f83b31e20f6bd611ee0d9d6eba231edb9b6150)


## Implement Access Pattern B (List Messages)
- First we did use local rds and dynamodb connection url and aws endpoint in `docker-compose.yml`& `backend-flask/lib/db.py`.
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/c04377b1679fca2d3504b132ad5b7840374aaf26)


