FROM python:3.9-alpine 

WORKDIR /backend-flask

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY . .

ENV FLASK_ENV=development

#this is metadata only and won't actually expose a port.
EXPOSE ${PORT}

CMD [ "flask", "run", "--host=0.0.0.0", "--port=4567"]