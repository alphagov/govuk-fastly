from json import loads
from difflib import unified_diff
from subprocess import run
from string import ascii_lowercase
from random import choice
from requests import get, patch
from boto3 import client

def find_vcls(plan):
  vcls = {}
  before = plan['prior_state']['values']['root_module']
  after = plan['planned_values']['root_module']

  for module in before:
    for resource in module['resources']:
      if resource['type'] == "fastly_service_vcl":
        address = resource['address']
        vcl = resource['values']['vcl'][0]['content']
        vcls[address] = {
          "before": vcl
        }
  for module in after:
    for resource in module['resources']:
      if resource['type'] == "fastly_service_vcl":
        address = resource['address']
        if address in vcls:
          vcl = resource['values']['vcl'][0]['content']
          vcls[address]['after'] = vcl
  return vcls

def generate_unified_diff(vcls):
  diffs = ""
  for address in vcls:
    vcl = vcls[address]
    before = vcl['before']
    if 'after' not in vcl:
      continue
    after = vcl['after']
    diff_gen = unified_diff(
      before.split("\n"),
      after.split("\n"),
      fromfile=f"{address}.vcl",
      tofile=f"{address}.vcl",
      lineterm=""
    )
    diffs += "\n".join(str(diff) for diff in diff_gen) + "\n"
  return diffs

def upload_to_s3(run_id, diffs):
  random_str = "".join(choice(ascii_lowercase) for i in range(0, 64))
  file_name = f"{run_id}-{random_str}.html"

  s3 = client("s3")
  s3.put_object(
    Bucket="govuk-fastly-diff",
    Key=file_name,
    Body=diffs.encode("utf-8"),
    ContentType="text/html",
    ACL="public-read"
  )

  return f"https://govuk-fastly-diff.s3.amazonaws.com/{file_name}"

def handler(event, context):
  tf_body = loads(event['body'])

  if tf_body['stage'] == "test":
    return ""
  
  run_id = tf_body['run_id']
  access_token = tf_body['access_token']
  plan_url = tf_body['plan_json_api_url']
  callback_url = tf_body['task_result_callback_url']

  plan = get(
    plan_url,
    headers={
      "Authorization": f"Bearer {access_token}"
    }
  ).json()

  vcls = find_vcls(plan)

  diffs = generate_unified_diff(vcls)

  html_diff = run(
    ["diff2html", "-i", "stdin", "-o", "stdout", "--title", "Fastly VCL Diff"],
    encoding="utf-8",
    capture_output=True,
    input=diffs
  ).stdout
  
  url = upload_to_s3(run_id, html_diff)

  if "local_only" not in tf_body:
    print(patch(
      callback_url,
      headers={
        "Authorization": f"Bearer {access_token}",
        "Content-Type": "application/vnd.api+json"
      },
      json={
        "data": {
          "type": "task-results",
          "attributes": {
            "status": "passed",
            "message": "Click Details for VCL diff",
            "url": url
          }
        }
      }
    ).text)

  return url
