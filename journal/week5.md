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


## Implement Access Pattern B (List Conversations for The Logged-in User)
- First we did use local rds and dynamodb connection url and aws endpoint in `docker-compose.yml`& `backend-flask/lib/db.py`.
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/c04377b1679fca2d3504b132ad5b7840374aaf26)

- Edit `data_message_groups():` function inside `app.py` to get the user id from cognito from JWT (after signing in).
- Edit `message_groups.py` , we need to have access to our database to get the uuid corresponding to the cognito user id.
- Create `backend-flask/db/sql/users/uuid_from_cognito_user_id.sql` to return uuid from our database because it is different than the cognito id.
- Now we have to run  `backend-flask/bin/db/update_cognito_user_ids` script that will fill cognito id with its actual value instead of MOCK from seed data script. 
**Note**: I had to register with a new email and used the username as andrewbrown SAME AS handle in `seed` script.
- The Conversations will be listed after getting the uuid which is requierd for our access pattern Using `Ddb.list_message_groups(ddb, my_user_uuid)` function.<br>

- Now we face `401 error` because we aren't authenticated (the tocken isn't passed to all pages)
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/cbd2c62b77fea84a76e2c72777878e6d004969f8)

### Client-Side (Update Bearer Access Token Header)
- Remove Cookies part from all pages because we use local storage for storing access tocken (I think).
- Pass the access tocken header to all of the pages.
- Check Auth using Amplify for all pages using a function we stored in a seperate file `frontend-react-js/src/lib/CheckAuth.js`
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/741f2ef5d167ce3db524fff1dd4ecf062c63c8da)

## Implement Access Pattern A (Click The Conversation to Show Messages)
### Client-Side
```js
// App.js
    path: "/messages/:message_group_uuid",
```
```js
// MessageGroupPage.js
    const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/messages/${params.message_group_uuid}`
```
- Passed the `message_group_uuid` to the `MessageGroupPage.js` using the params which is a way to access URL parameters.

- for the transition after clicking on a conversation to list messages to work, we need to change the "Click Value".
So, inside `components/MessageGroupItem.js` we change `if (params.message_group_uuid == props.message_group.uuid)`
and the `return`.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/049426861dc282536a010da821017ee16cf35bee)
### Server-Side (Python)
- Edit `app.py` to verify JWT tocken and get cognito uuid to return our uuid from the sql database
- Implement `messages.py` to
  - pass the user id from our database "TO DO" (this step is to do permession check so that only authorized users access the messages, because NOW any one who has the `message_group_uuid` can see it)
  - pass `message_group_uuid` to our dynamodb table to get all of the messages.
- Edit `ddp.py` to have `list_messages(client,message_group_uuid):` function ready to list the messages once we have the `message_group_uuid` "ALREADY DONE THAT STEP

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/9801525781fe0469f69bb292cff190b7bc482a08)


## Implement Access Pattern D (Create a Message in Existing Conversation)
### Clinet-Side
- Pass the message_group_uuid in the POST request because it is required for our access pattern to know where to add this message.
- The reason for `json.handle` is to pass the handle if we want to create a new conversation (Pattern C), so we use the handle to create a message group with that user.
```js
// components\MessageForm.js
let json = { 'message': message }
if (params.handle) {
  json.handle = params.handle
} else {
  json.message_group_uuid = params.message_group_uuid
}
```
- `setMessage('');` function will reset the form after creating the message.
```js
// components\MessageForm.js
      if (res.status === 200) {
        props.setMessages(current => [...current,data]);
        setMessage('');
      }
```
> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/76315b4d8dd2361d1245ad02be57b0631a8beaf6)

### Server-Side (Python)
#### `app.py`
- Did the normal auth as usual to get the `cognito_user_uuid`.
- Edit `app.py` to get the `message_group_uuid`, `handle`, `message` from the front-end and pass it to `CreateMessage.py` service
```python
# app.py
@app.route("/api/messages", methods=['POST','OPTIONS'])
@cross_origin()
def data_create_message():
  message_group_uuid   = request.json.get('message_group_uuid',None)
  user_receiver_handle = request.json.get('handle',None)
  message = request.json['message'] # the reason why `.get` isn't here because this field is mandatory but others depend on the mode, so they might be empty so they return error that's why we used `.get`
  model = CreateMessage.run(
    mode="update",
    message=message,
    message_group_uuid=message_group_uuid,
    cognito_user_id=cognito_user_id
  )
```
#### `create_message.py`
- Get users from sql template and seperate them to sender and receiver.
- Depending on the mode, it create message group or update the existing conversation with a new message.
- It uses `ddb.py` `data = Ddb.create_message()` function to create the message.

#### `backend-flask/db/sql/users/create_message_users.sql`
- This SQL code will get two users (sender = cognito_user_id & reciever = user_receiver_handle).
Then it will add a new column with title kind and it seperate sender user by putting `sender` in its value
and the receiver by putting `recv` in its value.
```sql
SELECT 
  users.uuid,
  users.display_name,
  users.handle,
  CASE users.cognito_user_id = %(cognito_user_id)s
  WHEN TRUE THEN
    'sender'
  WHEN FALSE THEN
    'recv'
  ELSE
    'other'
  END as kind
FROM public.users
WHERE
  users.cognito_user_id = %(cognito_user_id)s
  OR 
  users.handle = %(user_receiver_handle)s
```

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/12f25e44554367b613f2a8256eb658980db64d52)

## Implement Access Pattern C (Create a Message in NON-Existing Conversation)
### Clinet-Side
- Add new URL (new page) to our app to be able to create a new conversation.
- Import the new page at the top
```js
// App.js
import MessageGroupNewPage from './pages/MessageGroupNewPage';
{
  path: "/messages/new/:handle",
  element: <MessageGroupNewPage />
},
```
#### `components/MessageGroupNewItem.js`
- The reason for creating this page is to be able to click on the user to send the message to.
- In the future after you click a person profile and then click on message him ,you will be redirected to this page.
- In order for this Item to be shown in UI, we need to add it in this page `MessageGroupFeed.js`
```js
import MessageGroupNewItem from './MessageGroupNewItem';

  let message_group_new_item;
  if (props.otherUser) {
    message_group_new_item = <MessageGroupNewItem user={props.otherUser} />
  }

      <div className='message_group_feed_collection'>
          {message_group_new_item}
```

#### `MessageGroupNewPage.js`
- It defines two functions, `loadUserShortData` and `loadMessageGroupsData`, which use the fetch API to retrieve data from the backend.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/dad3e28c8656daa39d44de1f9aa31509f27db537)

### Server-Side (SQL & Python)
- Add new user to our mock database to have a third user who doesn't have existing conversation.
```sql
./connect

INSERT INTO public.users (display_name, email, handle, cognito_user_id)
VALUES ('Londo Londo','Londo@londo.co' , 'londo' ,'MOCK');
```

#### `app.py`
- Create new API Endpoint to show some profile information in that new page we created
```python
from services.users_short import *

@app.route("/api/users/@<string:handle>/short", methods=['GET'])
def data_users_short(handle):
  data = UsersShort.run(handle)
  return data, 200
```

- Add a new service `backend-flask/services/users_short.py` that will call this sql template `backend-flask/db/sql/users/short.sql`

```sql
SELECT
  users.uuid,
  users.handle,
  users.display_name
FROM public.users
WHERE 
  users.handle = %(handle)s
```
- That SQL will return display_name,handle,uuid  of that 3rd user (the one we want to message)
- That data will be pushed back to our new created page using our new created API Endpoint.

#### `create_message.py`
- When we want to create new conversation through UI we will be on a url of something like this `https://3000-*****.gitpod.io/messages/new/bayko` so that means that we won't pass a message UUID so in `app.py` we will be on mode `create` inside this function
```py
# app.py
    if message_group_uuid == None:
      # Create for the first time
      model = CreateMessage.run(
        mode="create",
        message=message,
        cognito_user_id=cognito_user_id,
        user_receiver_handle=user_receiver_handle
      )
```
- we will use this function
```py
# create_message.py
      elif (mode == "create"):
        data = Ddb.create_message_group(
          client=ddb,
          message=message,
          my_user_uuid=my_user['uuid'],
          my_user_display_name=my_user['display_name'],
          my_user_handle=my_user['handle'],
          other_user_uuid=other_user['uuid'],
          other_user_display_name=other_user['display_name'],
          other_user_handle=other_user['handle']
        )
```
#### `Ddb.create_message_group()`
- This function will put these items into our DynamoDB as a batchwrite
```py
    items = {
      table_name: [
        {'PutRequest': {'Item': my_message_group}},
        {'PutRequest': {'Item': other_message_group}},
        {'PutRequest': {'Item': message}}
      ]
    }
```
- It will return the message uuid only and this value will be used in the Front-End to redirect the user to its new created message using this code in the front end 


> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/4f937c20745fa7022b461fb07fc7b2b29a2f3463)

## Implement Access Pattern E (Update the Message Shown in the Conversation Groups)
#### `backend-flask/bin/ddb/schema-load`
- Add GlobalSecondaryIndexes to be able to undex on `message_group_uuid` to update the Message in that `message_group_uuid`.
- Activate `DynamoDB stream "new image"` from the same script instead of AWS Console.

#### `docker-compose-gitpod.yml`
- comment out `AWS_ENDPOINT_URL` to work on Production DynamoDB.
```yml
environment:
  # AWS_ENDPOINT_URL: "http://dynamodb-local:8000"
```
### Steps in AWS Console
- In the VPC console, create an endpoint named `cruddur-ddb`, choose services with DynamoDB, and select the default VPC and **route table**. "I've missed setting route table, and it cost me 1 hour"
- Create a new Lambda function called `cruddur-messaging-stream` and enable VPC in its advanced settings and two subnets and default SG.
- Deploy the code From `aws/lambdas/cruddur-messaging-stream.py`.
- Add permission of `AWSLambdaInvocation-DynamoDB` to the Lambda IAM role && inline policies from `aws/policies/cruddur-message-stream-policy.json`.
- Finally, in the DynamoDB console, create a new trigger and select `cruddur-messaging-stream` lambda function.

> Check commit details [here](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/5ad8370c845c721af0a6760169024b053a73a4ce)