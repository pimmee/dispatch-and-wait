# dispatch-and-wait

A GitHub Action that triggers a workflow and waits for it to succeed before proceeding. Largely based off of [Trigger Workflow and Wait](https://github.com/zigiai/dispatch-and-wait), with the modification that `workflow_name` is provided to ensure the correct workflow is found.

## Arguments

| Name             | Required | Default | Description                                                                                                                                     |
| ---------------- | -------- | ------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `owner`          | true     | N/A     | Owner of the repo where the workflow is to be triggered.                                                                                        |
| `repo`           | true     | N/A     | The repo where the workflow is to be triggered.                                                                                                 |
| `token`          | true     | N/A     | An access token with write permissions to `repo`.                                                                                               |
| `event_type`     | true     | N/A     | The event type parameter to be passed in the repository dispatch request.                                                                       |
| `workflow_name`  | true     | N/A     | The name of the workflow to be triggered.                                                                                                       |
| `client_payload` | false    | `"{}"`  | The client payload parameter to be passed in the repository dispatch request. Should be in the format `'{"key1": "value1", "key2": "value2"}'`. |
| `wait_time`      | false    | `10`    | Time to wait between workflow status checks, in seconds.                                                                                        |
| `max_time`       | false    | `60`    | Maximum time to wait for the workflow to finish before exiting, in seconds.                                                                     |

## Example usages

Basic use with user-added secret called `ACCESS_TOKEN`:

```
- uses: pimmee/dispatch-and-wait@v1.0.0
  with:
    owner: username
    repo: reponame
    token: ${{ secrets.ACCESS_TOKEN }}
    event_type: ping
    workflow_name: Backend Deploy to Production
```

Use with default `GITHUB_TOKEN` and optional inputs:

```
- uses: pimmee/dispatch-and-wait@v1.0.0
  with:
    owner: username
    repo: reponame
    token: ${{ secrets.GITHUB_TOKEN }}
    event_type: ping
    workflow_name: Backend Deploy to Production
    client_payload: '{"ref": "master"}'
    wait_time: 5
    max_time: 120
```
