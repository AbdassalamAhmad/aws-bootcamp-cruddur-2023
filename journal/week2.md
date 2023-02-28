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

**Explore attributes of our custom span**


**Important Notes from Live Stream**:
- Why Open telementary exist?<br>
All observabilty platforms has standard for sending data. then open elemerty made a standard and all
platforms used it now even AWS x-rays use it now