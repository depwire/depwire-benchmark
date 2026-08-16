# Corrected August 2026 Task C Results

The July results and their comparative conclusions remain withdrawn. They used
an agent-visible answer key, an incomplete 81-file oracle, and unequal launch
directories.

These are the observed results from one corrected session per arm. Every arm
used the same answer-key-free prompt, Payload commit, working directory, model,
effort level, disabled subagent/web tools, and 126-file hidden oracle.

| Arm | Duration | Correct | Extra | TSC errors | Tests | Score | Tool calls | Depwire calls | Cost |
|---|---:|---:|---:|---:|---|---:|---:|---:|---:|
| No Depwire | 10m 16s | 126/126 | 2 | 0 | PASS | 129/131 | 133 | 0 | $3.08 |
| Depwire Basic | 11m 11s | 126/126 | 2 | 0 | FAIL | 124/131 | 129 | 0 | $2.86 |
| Depwire Guided | 9m 13s | 126/126 | 2 | 0 | PASS | 129/131 | 85 | 2 | $2.14 |

The Basic test failure was the repository's network-sensitive
`create-payload-app` test timing out after 90 seconds. The agent's own test run
hit the same timeout; the locked harness rerun records the failure as observed.
No-Depwire and Guided passed all 1,728 tests in their harness runs.

## What this run supports

- The answer-key-free task produced real discovery: all three agents found and
  structurally updated all 126 required files.
- Merely making Depwire available did not cause adoption. Basic made zero
  Depwire calls and therefore cannot support attribution to Depwire tool use.
- Guided called `connect_repo` and `affected_files`, then used normal repository
  search to expand beyond the connected package. It finished with fewer total
  tool calls and lower cost than the other two observed sessions.
- All three changed the same two excluded codemod fixtures. Those files are
  literal input/output data for an unrelated codemod, not compiled constructor
  consumers, so they remain extras rather than part of the 126-file oracle.

## What this run does not support

This is one session per arm. Agent variance and the flaky test are large enough
that timing, cost, and tool-call differences are exploratory observations, not
general performance estimates or causal guarantees. Correctness saturated in
all arms, so this run also does not show a correctness advantage for Depwire.

## Scorer audit

The initial scoring pass incorrectly marked `APIError.ts` as missed because the
readonly property was stored in `ExtendableError` and inherited by `APIError`.
All three branches used that valid design. The AST check was corrected and the
frozen commits rescored from 125/126 to 126/126; no session artifact or agent
change was rerun. The correction is documented in
`PRE-REGISTRATION-2026-08.md`.

## Artifacts

Each arm publishes its result JSON, Claude stream transcript, TypeScript output,
unit-test output, and a Git format patch for the exact `branch_commit` recorded
in the JSON. The patches apply to the pinned `benchmark-baseline` commit.
