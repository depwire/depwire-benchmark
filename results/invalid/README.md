# Invalid results — retained, not comparable

All files here were produced under the pre-rebuild harness in which
`TASK_C.md` contained the full ground-truth file list ("Ground Truth —
Files That MUST Be Updated (81 files)"). Correctness was therefore
incapable of differentiating arms, and no figure derived from these
runs is valid.

- `*-20260721-*` — the three July arms behind the withdrawn 36% / 27%
  claims (withdrawn in commit 6b5bb4c).
- `*-20260816-*` — two August basic runs, same contaminated prompt.
- `*-20260818-155625-transcript.jsonl` — stray transcript from an
  aborted Aug 18 session, not part of the six frozen sessions.

Valid data lives one directory up, produced by the rebuilt harness
(d41968e and later) and published in 7817f16. Retained per the same
policy as commits a7367e0 / 54347e4: invalid attempts are kept and
labeled, never deleted or silently mixed with valid data.
