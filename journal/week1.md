# Week 1 — App Containerization

### Running Flask App Locally
I've tried running it locally and it didn't work.
I'm using windows machine and couldn't do the `export FRONTEND_URL="*" && export BACKEND_URL="*"` commands.<br> 
I've tried using `setx` command and succeded in doing the env vars part.
![image](https://user-images.githubusercontent.com/83673888/220041362-7831572b-77c3-491c-b679-b9eba33cce20.png)
But still wasn't able to run it and got this error.
![image](https://user-images.githubusercontent.com/83673888/220041322-6b49d9d3-1cd6-472c-af80-44c6459b376b.png)

So, I **skipped the local part and head to the dockerization part**.

## Running Cruddur Front-End & Back-End using Docker
### Back-End Docker part

- Created [backend-flask/Dockerfile]() locally and built an image using the next command<br>
- `docker build -t backend-flask ./backend-flask`
- Run the image using this command `docker run --rm -p 4567:4567 -it -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flask`




