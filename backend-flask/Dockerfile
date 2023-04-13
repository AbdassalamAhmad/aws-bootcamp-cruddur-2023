FROM python:3.10-slim-buster

WORKDIR /backend-flask

COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt

COPY . .



#this is metadata only and won't actually expose a port.
EXPOSE 4567
# CMD ["gunicorn", "-b", ":4567", "app:app"]
CMD [ "flask", "run", "--host=0.0.0.0", "--port=4567", "--debug"]