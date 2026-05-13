---
description: Diagnose HCP Terraform run logs using Terraform Cloud API calls
argument-hint: "[RUN_ID=<run-id>] [WORKSPACE=rag-studio] [ORG=bilbyai] [HOSTNAME=app.terraform.io] [PAGE_SIZE=5]"
---

Diagnose Terraform Cloud/HCP Terraform run failures for this repository.

Invocation arguments: $ARGUMENTS

Use `platform/infra/terraform/hcp-run-logs.sh` as the source of truth for the API flow and defaults:

- `HOSTNAME`: default `app.terraform.io`
- `ORG`: default `bilbyai`
- `WORKSPACE`: default `rag-studio`
- `PAGE_SIZE`: default `5`
- Token source: `TFE_TOKEN`; if unset, read `~/.terraform.d/credentials.tfrc.json` at `.credentials[HOSTNAME].token`
- API headers:
  - `Authorization: Bearer <token>`
  - `Content-Type: application/vnd.api+json`

Do not print or expose the token. Do not guess the run root cause without reading the relevant plan/apply log.

Required API calls:

1. If `RUN_ID` is not supplied, resolve the workspace ID:

   `GET https://{HOSTNAME}/api/v2/organizations/{ORG}/workspaces/{WORKSPACE}`

   Extract:

   ```bash
   jq -r '.data.id'
   ```

   Equivalent curl shape:

   ```bash
   curl -fsS \
     -H "Authorization: Bearer $$TFE_TOKEN" \
     -H "Content-Type: application/vnd.api+json" \
     "https://$$HOSTNAME/api/v2/organizations/$$ORG/workspaces/$$WORKSPACE"
   ```

2. If `RUN_ID` is not supplied, list recent runs for that workspace:

   `GET https://{HOSTNAME}/api/v2/workspaces/{WORKSPACE_ID}/runs?page%5Bsize%5D={PAGE_SIZE}`

   Extract run candidates:

   ```bash
   jq -r '.data[] | [.id, .attributes.status, .attributes.message, .attributes."created-at"] | @tsv'
   ```

   Pick the newest run that matches the user's request, prioritizing failed, errored, canceled, or pending runs. If the correct run is ambiguous, ask which run to inspect.

3. Fetch the run with plan/apply relationships:

   `GET https://{HOSTNAME}/api/v2/runs/{RUN_ID}?include=plan,apply`

   Extract component IDs:

   ```bash
   jq -r '.data.relationships.plan.data.id // empty'
   jq -r '.data.relationships.apply.data.id // empty'
   ```

   Also inspect useful run metadata:

   ```bash
   jq '.data.attributes | {status, message, "created-at", "status-timestamps"}'
   ```

4. If a plan ID exists, fetch the plan record and read its log URL:

   `GET https://{HOSTNAME}/api/v2/plans/{PLAN_ID}`

   Extract:

   ```bash
   jq -r '.data.attributes."log-read-url"'
   ```

5. If an apply ID exists, fetch the apply record and read its log URL:

   `GET https://{HOSTNAME}/api/v2/applies/{APPLY_ID}`

   Extract:

   ```bash
   jq -r '.data.attributes."log-read-url"'
   ```

6. Fetch each returned `log-read-url` directly:

   ```bash
   curl -fsS "$$LOG_READ_URL"
   ```

   This URL is returned by Terraform Cloud for log reads; use it as-is rather than prefixing `/api/v2`.

Diagnosis workflow:

- If an apply exists, inspect the apply log first, then the plan log when the apply log points back to planning or provider configuration.
- If no apply exists, inspect the plan log.
- For a focused error view, read both available logs and parse JSON lines:

  ```bash
  jq -R 'fromjson? | select(.["@level"] == "error")'
  ```

- Also scan raw log text for Terraform diagnostics and provider failures, including `Error:`, `│ Error:`, `diagnostic`, `failed`, `denied`, `forbidden`, `unauthorized`, `quota`, `timeout`, `invalid`, `not found`, and provider-specific API error messages.
- Identify the failing Terraform resource/module address, provider, API operation, and exact error message when present.
- Distinguish plan-time failures from apply-time failures.
- Report the likely root cause, the evidence from the logs, and the smallest next action to fix or verify it.
- Include the run ID, workspace, status, and whether the diagnosis came from the plan log, apply log, or both.
