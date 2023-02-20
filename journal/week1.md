# Week 1 — App Containerization

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
![image](https://user-images.githubusercontent.com/83673888/220186386-6d2442f6-2288-4bcd-bd09-50a1fea97ad0.png)
- **NOTE:** I already have very good understanding of Docker so I skipped running other commands and headead to Front-End.

### Front-End Docker Part

- Created [frontend-react-js/Dockerfile](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/Dockerfile) locally.
- Built a Docker image using this command `docker build -t frontend-react-js ./frontend-react-js`
- Run the image using this command `docker run -p 3000:3000 -d frontend-react-js`


## Running Cruddur App using Docker-Compose
- Created [docker-compose.yml]() at the root of my project.
