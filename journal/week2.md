# Week 2 — Distributed Tracing
## Required Homework

## HoneyComb

- Add HoneyComb opentelemetry libraries in `requirements.txt` and used pip to install them.
```txt
opentelemetry-api 
opentelemetry-sdk 
opentelemetry-exporter-otlp-proto-http 
opentelemetry-instrumentation-flask 
opentelemetry-instrumentation-requests
```
- Import these libraries in `app.py`
```python
# HoneyComb ---------
from opentelemetry import trace
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.sdk.trace.export import ConsoleSpanExporter, SimpleSpanProcessor
```
- Create and initialize a tracer and Flask instrumentation to send data to Honeycomb.
- Add 2 lines of code that will output logs to STDOUT of flask container.(for debugging).
```python
simple_processor = SimpleSpanProcessor(ConsoleSpanExporter())
provider.add_span_processor(simple_processor)
```
- Set HoneyComb API env var in gitpod for docker compose backend that will make honeycomb know where to send the data. 
```yml
      OTEL_SERVICE_NAME: 'backend-flask'
      OTEL_EXPORTER_OTLP_ENDPOINT: "https://api.honeycomb.io"
      OTEL_EXPORTER_OTLP_HEADERS: "x-honeycomb-team=${HONEYCOMB_API_KEY}"
```
- Created a tracer in `home_activities.py`
```py
from opentelemetry import trace
tracer = trace.get_tracer("home.Activities") # this will show up in attribute of field library
```

- **Created a custom span in home activities** to show it in honeycomb.
- **Created a custom attribute inside that span**
```py
with tracer.start_as_current_span("home-activites-mock-data"):
    span = trace.get_current_span() # this will get whatever span it's in
    now = datetime.now(timezone.utc).astimezone()
    span.set_attribute("app.now", now.isoformat()) # this app.now attribute will show inside this span "home-activites-mock-data" , its data is the time now in ISO foramt.
```
- Custom fields are prefix with app so we could find them easily like `"app.now"`

**Run queries to explore traces within Honeycomb.io**
![image](https://user-images.githubusercontent.com/83673888/221773086-9cec5304-7418-4f3e-9bf7-dfc58d0b65b3.png)

**Explore attributes of our custom span**
![image](https://user-images.githubusercontent.com/83673888/221773115-fdc28c31-830c-4c61-9c25-441bf9eaf80a.png)


**Important Notes from Live Stream**:
- Why opentelemetry exist?<br>
All observabilty platforms has standard for sending data. then opentelemetry made a standard and all
platforms used it now even AWS x-rays use it now.

- when setting any env like honecompo api key and then using docker compose up from
  VScode UI, it won't pick up the env because it is set in other terminal.<br>
*SOLVING THE ISSUE:*
- either put the env in gp env and close the workspace and open a new one.
- or use docker compose from the same termianl.

## AWS X-RAY
### Instrument AWS X-Ray into Back-End Flask Application
```sh
export AWS_REGION="eu-south-1"
gp env AWS_REGION="eu-south-1"
```

- Add to the `requirements.txt` and install it using `pip install -r requirements.txt`.

```py
aws-xray-sdk
```

- Add to `app.py` the import and configureation of x-rays.

```py
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware
xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='backend-flask', dynamic_naming=xray_url)
# above lines should be above app Flask.
app = Flask(__name__)
# next line should be after app Flask.
XRayMiddleware(app, xray_recorder)
```
- Run this command to create a log group inside AWS X-Ray (CcloudWatch Logs).
```sh
aws xray create-group \
   --group-name "Cruddur" \
   --filter-expression "service(\"backend-flask\")"
```
- Added `aws/json/xray-sampling-rule.json`.

```json
{
  "SamplingRule": {
      "RuleName": "Cruddur",
      "ResourceARN": "*",
      "Priority": 9000,
      "FixedRate": 0.1,
      "ReservoirSize": 5,
      "ServiceName": "backend-flask",
      "ServiceType": "*",
      "Host": "*",
      "HTTPMethod": "*",
      "URLPath": "*",
      "Version": 1
  }
}
```
- Run this command to create a sampling rule that we created above.
```sh
aws xray create-sampling-rule --cli-input-json file://aws/json/xray-sampling-rule.json
```

### Configure and provision X-Ray daemon within docker-compose and send data back to X-Ray API

- **Two ways for Installing X-Ray**:
  - The two lines above [this link](https://github.com/omenking/aws-bootcamp-cruddur-2023/blob/week-2/journal/week2.md#add-deamon-service-to-docker-compose) will install X-Ray manually (not preferred).
  - The better way is using docker-compose (preferred).
```yml
  xray-daemon:
    image: "amazon/aws-xray-daemon"
    environment:
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      AWS_REGION: "eu-south-1"
    command:
      - "xray -o -b xray-daemon:2000"
    ports:
      - 2000:2000/udp
```
- Add these two env vars to my backend-flask in `docker-compose-gitpod.yml` file
```yml
      AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"
      AWS_XRAY_DAEMON_ADDRESS: "xray-daemon:2000"
```

### Observe X-Ray traces within the AWS Console
**proof of work**
![image](https://user-images.githubusercontent.com/83673888/222731020-f5ee2edb-a94f-45e3-8892-4a393a3ac018.png)


> See My Implementation here [commit details](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/810593ccf7171810bb04ac28ed117773afa0b209)


**Important Note from AWS X-Ray Video**:
- It is better to do any config in aws using CLI instead of AWS UI Console,<br>
 because they change it a lot. and for you to remember what have you made.


## AWS CloudWatch Logs
### Install WatchTower and Import It in the Code
- Add to the `requirements.txt`
```sh
watchtower
```

- Imported libraries into `app.py`

```
import watchtower
import logging
from time import strftime
```
### Write a Custom Logger to Send Application Log Data to CloudWatch Log Group.
- Init CloudWatch Logs
```py
# Configuring Logger to Use CloudWatch
LOGGER = logging.getLogger(__name__)
LOGGER.setLevel(logging.DEBUG)
console_handler = logging.StreamHandler()
# the next line will setup log group inside CloudWatch named cruddur
cw_handler = watchtower.CloudWatchLogHandler(log_group='cruddur')
LOGGER.addHandler(console_handler)
LOGGER.addHandler(cw_handler)
# this is how we do logs 
LOGGER.info("test log from app.py")
```
- This will log ERRORS to CloudWatch
```py
@app.after_request
def after_request(response):
    timestamp = strftime('[%Y-%b-%d %H:%M]')
    LOGGER.error('%s %s %s %s %s %s', timestamp, request.remote_addr, request.method, request.scheme, request.full_path, response.status)
    return response
```
- Set the env var in backend-flask for `docker-compose-gitpod.yml`

```yml
      AWS_DEFAULT_REGION: "${AWS_DEFAULT_REGION}"
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
```
- Finally, add a custom logging in `home_activities.py`, and edit a logger variable as follow
```py
# home_activities.py  
  def run(logger):
    logger.info("HomeActivities")

# app.py
@app.route("/api/activities/home", methods=['GET'])
def data_home():
  data = HomeActivities.run(logger=LOGGER)
  return data, 200
```
**Commented the logs to avoid spend because I'll be using Rollbar and HoneyComb**<br>
**Proof of work**
![image](https://user-images.githubusercontent.com/83673888/222212007-204bc4f0-7efb-4d60-aebb-ce7f7955479a.png)





## Rollbar
### Integrate Rollbar for Error Logging
- Followed  Andrew's repo for instructions on how to implement Rollbar [Andrew's repo rollbar](https://github.com/omenking/aws-bootcamp-cruddur-2023/blob/week-2/journal/week2.md#rollbar).
- Here is my work in [this commit](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/1a177ad7ae0ec3844f709c6bb47e02877b08ae27)
- I've also exported my credentials of rollbar and put them inside gitpod envs.

### Trigger an error and observe it
- Removed the return of the function from `home_activities.py` file.
**Proof of work**
> Erorrs Logging
![image](https://user-images.githubusercontent.com/83673888/222150782-17b93837-54a1-442f-9d88-533e00dcb599.png)
> See the error and solve it
![image](https://user-images.githubusercontent.com/83673888/222150930-87162598-8dbf-4c1a-9f98-bae6c0e74484.png)


## Homework Challenges
## HoneyComb

### Trying to Instrument Honeycomb for the frontend-application to observe network latency between frontend and backend[NOT FINISHED]
- I have managed to implement front-end tracing and it send a span once I open the home page.
- I wasn't be able to put front & back end together because I need more time to figure this out. (need to learn 3 more tools)
- **The Problem** they worked in two differen environments, but when I used same API fro both only the old one can send data.
- Resources to Solve the problem in the future [connecting-the-frontend-and-backend-traces](https://docs.honeycomb.io/getting-data-in/opentelemetry/browser-js/#connecting-the-frontend-and-backend-traces) , [otel-collector](https://docs.honeycomb.io/getting-data-in/otel-collector/).

> See My Implementation here [commit details](https://github.com/AbdassalamAhmad/aws-bootcamp-cruddur-2023/commit/fa4e4246c5d62d3cf886fbf0d71032ba49d73dd1)
![image](https://user-images.githubusercontent.com/83673888/222126304-f34e9cdd-d1b6-428b-b1c2-ec07581337ed.png)



### Add UserID Attribute inside a Custom Span 

- Added uuid inside `home_activities.py`
- we get uuid from results list of dicts, so every time a random user get picked and sent.
```py
random_user = randint(0,2)
uuid = results[random_user]['uuid'] 
span.set_attribute("app.uuid", uuid)
```
Reasons for choosing UserID as Attribute:
- To Know which user made a request.
- To solve user issue by Quering a trace by uuid to know where the problem happend
- To dignose latency per user.

### Run Custom Queries in Honeycomb and Save Them
- Run this custom query: Visualized BY Max(duration) (Latency) Grouped BY app.uuid
- Saved the resulting query to a Board to retreive it later.

![image](https://user-images.githubusercontent.com/83673888/221825939-b4475806-41e6-422b-b97b-8b87aa5815c9.png)


