# Week 1 — App Containerization
## Required Homework

## Running Cruddur App using Docker-Compose
- Created [docker-compose-local.yml](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/docker-compose-local.yml) at the root of my project.
- Changed Env Vars from gitpod to localhost.
- Removed volume bind from front-end because I didn't run `npm install` in my local machine.
- Run this command `docker-compose -f "docker-compose-local.yml" up --build`
- ![image](https://user-images.githubusercontent.com/83673888/220248434-9a35849e-83ad-4c6d-a6bb-a4ea76093628.png)

## Running Cruddur App on Gitpod
- Created this [docker-compose-gitpod.yml](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/docker-compose-gitpod.yml) file to run the app.
- Installed Docker Extension and added it to `.gitpod.yml` to install it everytime i open the workspace.
- Added a task to run `npm i` inside `./frontend-react-js` folder in the `.gitpod.yml`
- Run `docker compose -f "docker-compose-gitpod.yml" up -d --build` to see the app running.
- ![image](https://user-images.githubusercontent.com/83673888/220312889-6808ae01-4981-495c-b901-72a42924c33e.png)


## Write the Notification Endpoint for OpenAPI
```yml
  /api/activities/notifications:
    get:
      description: 'Return a feed of activity for people I follow'
      tags:
        - activities
      responses:
        '200':
          description: Returns an array of activities"
          content:
            application/json:
              schema: # this for refactoring code so it will be used in other parts of the code like in home activity
                type: array
                items:
                  $ref: '#/components/schemas/Activity'
```

## Write a Flask Backend Endpoint for Notifications
- Copied [home_activites.py](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/backend-flask/services/home_activities.py) file into [notifications_activities.py](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/backend-flask/services/notifications_activities.py) because they both have the same schema so they share the same structure of return ojects.
- Referenced the `notifications_activities.py` file inside [app.py](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/backend-flask/app.py)
- Added a function inside `app.py` to run the `notifications_activities.py` when someone click on it or if we go directly to its URL

## Implement a React Page for Notifications
- Added the notifications page js file [NotificationsFeedPage.js](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/src/pages/NotificationsFeedPage.js)
- Referenced the `NotificationsFeedPage.js` file inside `App.js` file.
- Should've edit the `DesktopNavigation.js` file to include notifications but it's already there.

#### Proof of Notifications Implementation
![image](https://user-images.githubusercontent.com/83673888/220822698-d5058cba-2af8-420f-ad11-7231d8715b5d.png)

## Run DynamoDB Local Container and Ensure it Works
- Added this code to my docker-compose file
```yml
  dynamodb-local:
    # https://stackoverflow.com/questions/67533058/persist-local-dynamodb-data-in-volumes-lack-permission-unable-to-open-databa
    # We needed to add user:root to get this working.
    user: root
    command: "-jar DynamoDBLocal.jar -sharedDb -dbPath ./data"
    image: "amazon/dynamodb-local:latest"
    container_name: dynamodb-local
    ports:
      - "8000:8000"
    volumes:
      - "./docker/dynamodb:/home/dynamodblocal/data"
    working_dir: /home/dynamodblocal
```
- Ensure that DynamoDB Local is working by trying to Create a table, an Item, List Tables, Get Records.

### Create a table
```shell
aws dynamodb create-table \
    --endpoint-url http://localhost:8000 \
    --table-name Music \
    --attribute-definitions \
        AttributeName=Artist,AttributeType=S \
        AttributeName=SongTitle,AttributeType=S \
    --key-schema AttributeName=Artist,KeyType=HASH AttributeName=SongTitle,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1 \
    --table-class STANDARD
```

### Create an Item
```shell
aws dynamodb put-item \
    --endpoint-url http://localhost:8000 \
    --table-name Music \
    --item \
        '{"Artist": {"S": "No One You Know"}, "SongTitle": {"S": "Call Me Today"}, "AlbumTitle": {"S": "Somewhat Famous"}}' \
    --return-consumed-capacity TOTAL  
```

### List Tables
```shell
aws dynamodb list-tables --endpoint-url http://localhost:8000
```

### Get Records
```shell
aws dynamodb scan --table-name Music --query "Items" --endpoint-url http://localhost:8000
```

## Run Postgres Container and Ensure it Works
- Added this code to my docker-compose file
```yml
  db:
    image: postgres:13-alpine
    restart: always
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=password
    ports:
      - '5432:5432'
    volumes: 
      - db:/var/lib/postgresql/data

volumes:
  db:
    driver: local
```
- Installed the postgres client into Gitpod
```yml
  - name: install postgres client
    init: |
      curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc|sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
      echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" |sudo tee  /etc/apt/sources.list.d/pgdg.list
      sudo apt update
      sudo apt install -y postgresql-client-13 libpq-dev
```
- Installed a postgres Extension to explore database
```yml
vscode:
  extensions:
    - cweijan.vscode-postgresql-client2
```

- Ensure that postgres is working by trying these commands
```shell
psql -U postgres --host localhost
# here we will enter the password

# the command \l will list databases
postgres=# \l
```
#### Proof of Postgres Extension & Client Working
![image](https://user-images.githubusercontent.com/83673888/220905968-18092eec-4ed4-47e9-bd5f-bea195d06496.png)


## Homework Challenges
## Running Dockerfiles Commands as a shell Script
- Build a shell script that will build & run both Front & Back End Dockerfile.
- Created a network to link front-end with back-end.
- Here is the file [build_run_dockerfiles.sh](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/build_run_dockerfiles.sh)

## Pushing Flask Back-End Image to Docker Hub
- Used `docker login` command to login to my docker hub account.
- Tag the image `docker tag backend-flask:latest abod98/backend-flask:bootcamp`
- Pushed the image `docker push abod98/backend-flask:bootcamp`
- Here is the [image url](https://hub.docker.com/r/abod98/backend-flask) in docker hub.

## Implement Multi-Stage Building for Front-End.
- Used `node:16.18` and `node:16.18-alpine` images for my first multi-stgae build.
- Used `node:16.18` and `nginx:stable-alpine` images for my second multi-stgae build.
- Faced a lot of issues in the nginx multi-stage and resolved alot of them:
- I had to configure `nginx.conf` file because If the container had to only serve static files, the default configuration would be sufficient. but in our case we also need to proxy requests for URLs that start with /api to the API container, so the default configuration is not sufficient.
- Added debug for home page for env of react backend, because env of gitpod didn't pass in docker compose even with actual value.<br>
when i tried passing env in dockerfile also didn't work but the actual value worked.<br>

when i attach shell to nginx and do `echo $REACT_APP_BACKEND_URL` it works but in the node.js app it won't
and it return undefined when using `console.log(process.env.REACT_APP_BACKEND_URL);`.

- Size Comparison `node = 358MB` while `nginx = 25.3MB`.
- Using Nginx Container I won't need to expose my API because I used nginx to proxy requests to api internally so I can make it private and don't map ports to it.
"Note that the api container does not need to map any ports, because it is now an internal service that only needs to be reachable by the client container, but not from the outside world."
- Finally, I'll use node image for development and nginx for last deployment.

- Here are the files added [docker-compose-nginx.yml](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/docker-compose-nginx.yml), [Dockerfile.node-node](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/Dockerfile.node-node), [Dockerfile.node-nginx](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/Dockerfile.node-nginx).

#### Resources Used for this Multi-Stage
- [how-to-dockerize-a-react-flask-nginx-project](https://blog.miguelgrinberg.com/post/how-to-dockerize-a-react-flask-project).

## Implement Two Healthchecks in both Local & GitPod Docker Compose Files
- Add health checks for front-end and backend with these two commands
- Front-End `curl --fail http://localhost:3000 || exit 1`
- Back-End `wget --no-verbose --tries=1 --spider http://localhost:4567/api/activities/home || exit 1`
- Replaced local host link with gitpod link in gitpod docker-compose file.
- Documented what these commands do inside both [docker-compose-local.yml](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/docker-compose-local.yml) AND [docker-compose-gitpod.yml](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/docker-compose-gitpod.yml)

## Launch EC2 Instance && Pull My Public Flask Image
- ![image](https://user-images.githubusercontent.com/83673888/220558794-f5a02325-3a8c-4c1e-95fd-bbf825ee828b.png)


## Running Flask App Locally
I've tried running it locally and it didn't work.
I'm using windows machine and couldn't do the `export FRONTEND_URL="*" && export BACKEND_URL="*"` commands.<br> 
I've tried using `setx` command and succeded in doing the env vars part.
![image](https://user-images.githubusercontent.com/83673888/220041362-7831572b-77c3-491c-b679-b9eba33cce20.png)<br><br>
But still wasn't able to run it and got this error.
![image](https://user-images.githubusercontent.com/83673888/220041322-6b49d9d3-1cd6-472c-af80-44c6459b376b.png)

So, I **skipped the local part and head to the dockerization part**.

## Running Cruddur Front-End & Back-End using Docker Individual Containers.
### Back-End Docker Part

- Created [backend-flask/Dockerfile](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/backend-flask/Dockerfile) locally.
- Built a Docker image using this command  `docker build -t backend-flask ./backend-flask`
- Run the image using this command `docker run --rm -p 4567:4567 -it -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flask`
- ![image](https://user-images.githubusercontent.com/83673888/220186386-6d2442f6-2288-4bcd-bd09-50a1fea97ad0.png)
- **NOTE:** I already have very good understanding of Docker so I skipped running other commands and headead to Front-End.

### Front-End Docker Part

- Created [frontend-react-js/Dockerfile](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/Dockerfile) locally.
- Built a Docker image using this command `docker build -t frontend-react-js ./frontend-react-js`
- Run the image using this command `docker run -p 3000:3000 -d frontend-react-js`

### Running Both Containers Together
- `docker network create try_app`
- `docker run -p 4567:4567 -it --network try_app -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flask`
- `docker run -p 3000:3000 -e REACT_APP_BACKEND_URL="http://127.0.0.1:4567" --network try_app -d frontend-react-js`
- ![image](https://user-images.githubusercontent.com/83673888/220197021-e303a4dd-3585-4ca0-8978-00028c9798e4.png)
