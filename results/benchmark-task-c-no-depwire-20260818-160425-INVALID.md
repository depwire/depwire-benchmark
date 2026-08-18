# Invalid session: benchmark-task-c-no-depwire-20260818-160425

- Status: invalid under pre-registration section 8
- Arm: `no_depwire`
- Runner branch: `benchmark-task-c-no-depwire-20260818-160425`
- Branch commit at failure: `691309b5c5` (unchanged `benchmark-baseline`)
- Resolved Claude binary: `/opt/homebrew/bin/claude`
- Logged Claude version: `2.1.71 (Claude Code)`
- Reason: Claude authentication infrastructure failed before the agent began
  work. The transcript records HTTP 401 and `OAuth access token has expired.
  Re-authenticate to continue.`
- Agent turns: 1 authentication-error result; no task work was performed.
- Runner outcome: exited before measurement and result-branch finalization when
  Claude Code returned exit status 1.
- Operator log: `runner-env-no-depwire-20260818-160424.log`
- Transcript: `benchmark-task-c-no-depwire-20260818-160425-transcript.jsonl`
- Disposition: retained and excluded from the `n=3` analysis. A valid
  replacement session was completed after re-authentication.
