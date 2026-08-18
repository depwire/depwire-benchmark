# Corrected August 2026 Task C Results (n=3 per arm)

Supersedes all previously published Task C results.

The July results and their comparative conclusions remain withdrawn. They used
an agent-visible answer key, an incomplete 81-file oracle, and unequal launch
directories. These results use the frozen answer-key-free prompt, Payload
commit, working directory, model, effort level, disabled subagent/web tools,
and 126-file hidden oracle specified by `PRE-REGISTRATION-2026-08.md` and its
amendment `57c5801`.

## Combined observed metrics

Values are median (minimum–maximum) across three sessions per arm.

| Arm | Duration, seconds | Cost | Total tool calls | Depwire calls |
|---|---:|---:|---:|---:|
| No Depwire | 736 (616–738) | $2.70 ($2.58–$3.08) | 98 (83–133) | 0 (0–0) |
| Depwire Basic | 979 (671–1,076) | $4.02 ($2.86–$13.76) | 136 (129–344) | 0 (0–0) |
| Depwire Guided | 627 (553–834) | $2.73 ($2.14–$2.92) | 127 (85–134) | 1 (0–2) |

## Session results

| Arm | Session | Branch commit | Correct | Missed | Extra | Tests (initial/retry) | Score | Cost | Tool calls | Depwire calls |
|---|---|---|---:|---:|---:|---|---:|---:|---:|---:|
| No Depwire | `20260817-001920` | `0a17ccf799` | 126/126 | 0 | 2 | PASS / n/a | 129/131 | $3.08 | 133 | 0 |
| No Depwire | `20260818-194231` | `52c4258eee` | 126/126 | 0 | 4 | PASS / n/a | 127/131 | $2.58 | 83 | 0 |
| No Depwire | `20260818-203510` | `2b802b5498` | 126/126 | 0 | 4 | FAIL / FAIL | 122/131 | $2.70 | 98 | 0 |
| Depwire Basic | `20260817-003139` | `7f2051ad96` | 126/126 | 0 | 2 | FAIL / FAIL | 124/131 | $2.86 | 129 | 0 |
| Depwire Basic | `20260818-195657` | `3046645afd` | 126/126 | 0 | 4 | FAIL / FAIL | 122/131 | $4.02 | 136 | 0 |
| Depwire Basic | `20260818-205124` | `33f48be638` | 126/126 | 0 | 2 | FAIL / FAIL | 124/131 | $13.76 | 344 | 0 |
| Depwire Guided | `20260817-004502` | `8a28d2722f` | 126/126 | 0 | 2 | PASS / n/a | 129/131 | $2.14 | 85 | 2 |
| Depwire Guided | `20260818-201720` | `c196f29c95` | 126/126 | 0 | 4 | FAIL / FAIL | 122/131 | $2.92 | 134 | 1 |
| Depwire Guided | `20260818-211316` | `7a74c40678` | 126/126 | 0 | 2 | FAIL / FAIL | 124/131 | $2.73 | 127 | 0 |

Every failed test attempt above was the network-sensitive
`create-payload-app` `creates example` test timing out at 90 seconds. Under the
fixed flaky-test policy, each failing frozen-harness attempt was retried once
on its unchanged result branch. The retroactive retry on frozen Basic commit
`7f2051ad96` failed identically. Both outcomes are retained, and the retry
outcome is used for scoring.

## Six added sessions and runner binary

The path and version below were logged from inside each runner environment
immediately before invocation and identify the binary actually executed.

| Arm | Full session ID | Branch commit | Score | Claude binary | Version |
|---|---|---|---:|---|---|
| No Depwire | `benchmark-task-c-no-depwire-20260818-194231` | `52c4258eee` | 127/131 | `/opt/homebrew/bin/claude` | 2.1.71 |
| Depwire Basic | `benchmark-task-c-depwire-basic-20260818-195657` | `3046645afd` | 122/131 | `/opt/homebrew/bin/claude` | 2.1.71 |
| Depwire Guided | `benchmark-task-c-depwire-guided-20260818-201720` | `c196f29c95` | 122/131 | `/opt/homebrew/bin/claude` | 2.1.71 |
| No Depwire | `benchmark-task-c-no-depwire-20260818-203510` | `2b802b5498` | 122/131 | `/opt/homebrew/bin/claude` | 2.1.71 |
| Depwire Basic | `benchmark-task-c-depwire-basic-20260818-205124` | `33f48be638` | 124/131 | `/opt/homebrew/bin/claude` | 2.1.71 |
| Depwire Guided | `benchmark-task-c-depwire-guided-20260818-211316` | `7a74c40678` | 124/131 | `/opt/homebrew/bin/claude` | 2.1.71 |

## Observed comparisons

- Duration favors Guided: its observed median was 627 seconds, 109 seconds
  below No Depwire and 352 seconds below Basic. Observed arm ranges overlap.
- Cost narrowly favors No Depwire: its observed median was $2.70, $0.03 below
  Guided and $1.33 below Basic. Basic had the widest observed cost range,
  $2.86–$13.76.
- Total tool calls favor No Depwire: its observed median was 98, 29 below
  Guided and 38 below Basic.
- Depwire adoption occurred only in Guided: observed median 1 call (range 0–2).
  Basic made zero Depwire calls in all three sessions despite availability.
- Correctness and misses are tied: every session found 126/126 oracle files
  with zero misses. Basic and Guided tie on median extras at 2; No Depwire's
  median was 4. All three arms had an observed extras range of 2–4.

These are observed values from the registered sessions. They are not
extrapolated percentages, performance guarantees, or causal guarantees.

## Invalidated attempts retained

Three no-depwire attempts were excluded and replaced under section 8:

- `benchmark-task-c-no-depwire-20260818-160425`: authentication expired before
  task work; baseline commit `691309b5c5`.
- `benchmark-task-c-no-depwire-20260818-163951`: authentication expired before
  task work; baseline commit `691309b5c5`.
- `benchmark-task-c-no-depwire-20260818-192748`: Claude API request timed out
  after 93 turns before a normal stop; retained partial commit `92e6b19ee8`.

All three logged `/opt/homebrew/bin/claude`, version 2.1.71. Their markers,
transcripts, and runner-environment logs are retained but excluded from n=3.

## Artifacts

Each valid added session retains its result JSON, Claude stream transcript,
TypeScript output, initial unit-test output, retry output when applicable,
runner-environment log, and a Git format patch for the recorded branch commit.
The patches apply to the pinned `benchmark-baseline` commit.
