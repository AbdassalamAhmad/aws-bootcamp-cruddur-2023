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


