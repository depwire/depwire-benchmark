# Invalid session: benchmark-task-c-no-depwire-20260818-192748

- Status: invalid under pre-registration section 8
- Arm: `no_depwire`
- Runner branch: `benchmark-task-c-no-depwire-20260818-192748`
- Retained partial branch commit: `92e6b19ee8bff42c68109e5026138872479fc934`
- Resolved Claude binary: `/opt/homebrew/bin/claude`
- Logged Claude version: `2.1.71 (Claude Code)`
- Reason: the Claude API timed out before the agent reached a stopping point.
  The transcript ends with `Request timed out`, `is_error: true`, and Claude
  Code exit status 1 after 93 turns.
- Partial attempt cost: `$1.03899575`
- Runner outcome: exited before measurement and normal result-branch
  finalization. The 13-file partial worktree was committed unchanged solely to
  retain the invalid artifact.
- Operator log: `runner-env-no-depwire-20260818-192747.log`
- Transcript: `benchmark-task-c-no-depwire-20260818-192748-transcript.jsonl`
- Disposition: retained and excluded from the `n=3` analysis. The required
  replacement session will be run.
