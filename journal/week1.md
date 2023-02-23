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
