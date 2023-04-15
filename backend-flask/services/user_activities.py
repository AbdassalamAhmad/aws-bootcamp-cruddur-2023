from datetime import datetime, timedelta, timezone
from aws_xray_sdk.core import xray_recorder

class UserActivities:
  def run(user_handle):

    model = {
      'errors': None,
      'data': None
    }

    now = datetime.now(timezone.utc).astimezone()
    
    if user_handle == None or len(user_handle) < 1:
      model['errors'] = ['blank_user_handle']
    else:
      now = datetime.now()
      results = [{
        'uuid': '248959df-3079-4947-b847-9e0892d1bab4',
        'handle':  'Andrew Brown',
        'message': 'Cloud is fun!',
        'created_at': (now - timedelta(days=1)).isoformat(),
        'expires_at': (now + timedelta(days=31)).isoformat()
      }]
      model['data'] = results
    
    # xray ---
    with xray_recorder.capture('user_activity_time') as subsegment1:
      subsegment1.put_annotation('time_now', now.isoformat())

      with xray_recorder.capture('user_activity_length') as subsegment2:
        subsegment2.put_annotation("app_results_length", len(results))

    return model