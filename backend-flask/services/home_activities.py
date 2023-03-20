from datetime import datetime, timedelta, timezone
#from opentelemetry import trace
#from random import randint
#tracer = trace.get_tracer("home.Activities")

from lib.db import db


class HomeActivities:
  def run(cognito_user_id=None):
    # CloudWatch Logs ----
    #logger.info("HomeActivities")

    # # HoneyComb ---------
    # with tracer.start_as_current_span("home-activites-mock-data"):
    #   span = trace.get_current_span()
    #   now = datetime.now(timezone.utc).astimezone()
    #   span.set_attribute("app.now", now.isoformat()) # this app.now attribute will show inside this span "home-activites-mock-data" , its data is the time now in ISO foramt.

# Here we were having mock-up results to play with using monitoring tools.
# Now we replaced them with real api call:

    # # HoneyComb ---------
    # random_user = randint(0,2)
    # uuid = results[random_user]['uuid'] 
    # span.set_attribute("app.uuid", uuid)

    # span.set_attribute("app.results_length", len(results))


    sql = db.template('activities','home')
    results = db.query_array_json(sql)
    return results