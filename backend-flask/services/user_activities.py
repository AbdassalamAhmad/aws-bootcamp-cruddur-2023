# from aws_xray_sdk.core import xray_recorder
from lib.db import db

class UserActivities:
  def run(user_handle):

    model = {
      'errors': None,
      'data': None
    }
    
    if user_handle == None or len(user_handle) < 1:
      model['errors'] = ['blank_user_handle']
    else:

      sql = db.template('users','show_profile_and_its_activities')
      results = db.query_object_json(sql, {'handle': user_handle})
      model['data'] = results
    
    # # xray ---
    # with xray_recorder.capture('user_activity_time') as subsegment1:
    #   subsegment1.put_annotation('time_now', now.isoformat())

    #   with xray_recorder.capture('user_activity_length') as subsegment2:
    #     subsegment2.put_annotation("app_results_length", len(results))

    return model