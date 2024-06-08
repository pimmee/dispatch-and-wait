function trigger_workflow {
  echo "Triggering ${INPUT_EVENT_TYPE} in ${INPUT_OWNER}/${INPUT_REPO}"

  expected_workflow_run_number=$(curl -s "https://api.github.com/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/runs?event=repository_dispatch" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Authorization: Bearer ${INPUT_TOKEN}" \
        | jq ".workflow_runs | map(select(.name == \"$INPUT_WORKFLOW_NAME\")) | first | .run_number")


  if [ "$workflow_expect_run_number" = "null" ]; then
    expected_workflow_run_number=0
  fi
  expected_workflow_run_number=$(( $expected_workflow_run_number + 1))

  workflow_trigger_response=$(curl -X POST -s "https://api.github.com/repos/${INPUT_OWNER}/${INPUT_REPO}/dispatches" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${INPUT_TOKEN}" \
    -d "{\"event_type\": \"${INPUT_EVENT_TYPE}\", \"client_payload\": ${INPUT_CLIENT_PAYLOAD} }")

  if [ -z "$workflow_trigger_response" ]
  then
    sleep 2
  else
    echo "Workflow failed to trigger"
    echo "$workflow_trigger_response"
    exit 1
  fi
}

function ensure_workflow {
  max_wait=10
  stime=$(date +%s)
  while [ $(( `date +%s` - $stime )) -lt $max_wait ]
  do
    workflow_runid=$(curl -s "https://api.github.com/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/runs?event=repository_dispatch" \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Authorization: Bearer ${INPUT_TOKEN}" \
      | jq ".workflow_runs | map(select(.name == \"$INPUT_WORKFLOW_NAME\" and .run_number==$expected_workflow_run_number)) | first | .id")

      # Check if the workflow_runid is valid (non empty string and not null)
      if [ -n "$workflow_runid" ] && [ "$workflow_runid" != "null" ]; then
        break
      fi
    sleep 2
  done

  # Exit if workflow_runid is empty string or null
  if [ -z "$workflow_runid" ] || [ "$workflow_runid" == "null" ]; then
    >&2 echo "No workflow run id found. Repository dispatch failed!"
    exit 1
  fi

  echo "Workflow run id is ${workflow_runid}"
}

function wait_on_workflow {
  stime=$(date +%s)
  conclusion="null"

  echo "Dispatched workflow run URL:"
  echo -n "==> "
  curl -s "https://api.github.com/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/runs/${workflow_runid}" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "Authorization: Bearer ${INPUT_TOKEN}" | jq -r '.html_url'

  while [[ $conclusion == "null" ]]
  do
    rtime=$(( `date +%s` - $stime ))
    if [[ "$rtime" -ge "$INPUT_MAX_TIME" ]]
    then
      echo "Time limit exceeded"
      exit 1
    fi
    sleep $INPUT_WAIT_TIME
    conclusion=$(curl -s "https://api.github.com/repos/${INPUT_OWNER}/${INPUT_REPO}/actions/runs/${workflow_runid}" \
    	-H "Accept: application/vnd.github.v3+json" \
    	-H "Authorization: Bearer ${INPUT_TOKEN}" | jq -r '.conclusion')

    if [ "$conclusion" == "failure" ]; then
      break
    fi
  done

  if [[ $conclusion == "success" ]]
  then
    echo "Suceeded"
  else
    echo "Failed (conclusion: $conclusion)!"
    exit 1
  fi
}

function main {
  trigger_workflow
  ensure_workflow
  wait_on_workflow
}

main
