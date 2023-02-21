#!/bin/bash

# build Back-End && Front-End Dockerfiles.
docker build -t backend-flask ./backend-flask
docker build -t frontend-react-js ./frontend-react-js

# create network to connect the two containers
docker network create try_app

# run both Front & Back End Containers  and remove them once stopped.
docker run --rm -dp 4567:4567 -it --network try_app -e FRONTEND_URL='*' -e BACKEND_URL='*' backend-flask
docker run --rm -dp 3000:3000 --network try_app -e REACT_APP_BACKEND_URL="http://127.0.0.1:4567" frontend-react-js

