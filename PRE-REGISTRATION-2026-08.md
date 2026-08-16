# Pre-Registration — Corrected August 2026 Three-Arm Rerun

**Original pre-registration:** 2026-08-16, commit `44f2f4f`

**Material amendment:** 2026-08-16, before any session under the corrected
harness

**Reason for amendment:** the audit discovered defects broader than the parser
comparison covered by the original document.

## 1. Status of earlier runs

The July runs and the August Basic attempt made before this amendment are not
arms in the corrected experiment. They used an agent-visible prompt containing
the complete answer key and a scoring oracle limited to 81 files even though
the requested constructor change affected consumers across the monorepo.

Those artifacts are retained for auditability. They may be described as invalid
harness runs, but they must not be combined with or compared numerically to the
corrected runs.

## 2. Experiment being run

All three arms will be rerun from the same pinned Payload baseline:

1. `no_depwire`: no Depwire MCP server and no Depwire-generated context.
2. `depwire_basic`: Depwire MCP tools plus the same generated `AGENTS.md` used
   by the guided arm, without the explicit graph-first workflow.
3. `depwire_guided`: the Basic environment plus
   `tasks/DEPWIRE_GUIDED_WORKFLOW.md`.

The Basic-versus-Guided contrast tests the effect of explicit workflow guidance
within a Depwire-enabled environment. The No-Depwire-versus-Basic contrast tests
the bundled Depwire environment (tools plus generated project context), not MCP
tool availability in isolation.

## 3. Locked harness conditions

- Repository: `payloadcms/payload`
- Commit: `1545e8758be9a887f3f1020592b3117adb54dd5f`
- Baseline branch: `benchmark-baseline`
- Depwire version in both enabled arms: `depwire-cli@1.14.2`
- Agent CLI: Claude Code `2.1.71`
- Model: `claude-opus-4-6`, high effort
- Execution: non-interactive `claude -p`, with session persistence disabled
- Subagent, WebSearch, and WebFetch tools: disabled in every arm
- Agent working directory in every arm:
  `repo/packages/payload`
- Agent-visible task in every arm: `tasks/TASK_C_PROMPT.md`
- Hidden scoring oracle: `tasks/TASK_C_GROUND_TRUTH.txt`
- Required source-file set: 126 files across the full monorepo
- Required verification commands:
  `cd packages/payload && npx tsc --noEmit`, then `pnpm test:unit` from the
  monorepo root

Every runner sources `scripts/task_c_common.sh`. Before creating a branch, the
guard verifies that all runners use the shared prompt, that neither the prompt
nor guided workflow contains answer-key material, that the hidden oracle has
126 entries, and that the oracle can be reproduced from the pinned baseline.
The prompt SHA-256 and enforced working directory are printed into every run.
The runner launches the agent process itself from that directory and refuses to
start if the Claude Code version differs from the locked version. This removes
operator launch-directory variance. Disabling subagents prevents delegation
strategy from dominating the cost comparison; disabling web tools prevents the
agent from retrieving the public scoring oracle.

## 4. Ground-truth scope decision

The scored scope is the correct engineering scope of the public constructor
change, not the old `packages/payload/src` subset:

- 1 core `APIError` class;
- 27 subclasses that call the base constructor;
- 98 source files that directly instantiate `APIError` across packages,
  examples, and tests.

Excluded:

- two `packages/codemod/.../merge.{input,output}.ts` transformation fixtures,
  because they are literal test data rather than compiled consumers;
- `.github/actions/ai-reviewer/dist/index.js`, because it is a generated bundle
  containing vendored dependency code rather than a source consumer.

The oracle is kept out of all agent-visible context. The solution validator
parses each required file with TypeScript and only credits it when every
relevant `new APIError(...)` or subclass `super(...)` call has an
UPPER_SNAKE_CASE string literal in the new first-argument position. The core
file must expose the required first constructor parameter and readonly
property.

## 5. Metrics and scoring

Recorded automatically:

- duration;
- changed files;
- structurally correct required files out of 126;
- missed and unrelated extra files;
- TypeScript exit code and error count;
- unit-test exit code and pass/fail counts;
- final score.

Extracted from the Claude stream transcript:

- cost;
- total tool calls;
- Depwire tool calls;
- model and turn count.

Quality assessment and any additional notes may be added manually with
`fill_manual.sh`.

Score:

- +1 for each changed required file whose complete constructor usage passes the
  structural validator;
- -1 for each changed file outside the 126-file oracle;
- -2 for each remaining TypeScript error;
- +5 if the unit-test command exits successfully;
- floor of zero; maximum 131.

Raw correctness, misses, extras, compiler output, and test output remain the
primary interpretation. The aggregate score is a compact summary, not a
substitute for those fields.

## 6. Interpretation fixed in advance

No old percentage or correctness claim will be reused. Results will be reported
as the observed values for these three corrected sessions.

- A Guided-versus-Basic difference may be described as evidence about workflow
  guidance in this run.
- A Basic-versus-No-Depwire difference may be described as evidence about the
  full Depwire-enabled setup in this run.
- Tool-call attribution must state the actual Depwire call counts. An arm with
  zero Depwire calls cannot support a claim that Depwire tool use caused its
  timing or cost.
- With one session per arm, every comparison is exploratory and high-variance.
  No percentage will be marketed as a general performance guarantee.
- July and pre-amendment August records are historical invalid runs, not a
  comparison group.

## 7. Publication commitment

All three corrected sessions will be published, including failures and
unfavorable results. Raw JSON, Claude stream transcript, exact result-branch
commit, compiler output, test output, prompt hash, model, cost, and tool-call
counts will accompany any narrative report.

## 8. Session invalidation rule

A corrected session is invalid and must be recorded and rerun only if:

- the agent or harness is launched with a prompt hash, baseline, working
  directory, Depwire version, or arm context different from this document;
- the harness, MCP server, test infrastructure, rate limit, or API fails before
  the agent reaches a stopping point;
- the operator accidentally exposes the hidden oracle to the agent;
- the agent explicitly cannot submit a completed attempt because of an
  infrastructure interruption.

A low score, missed files, unrelated edits, compiler failure, test failure,
high cost, high duration, or zero Depwire calls is a valid result and is not a
reason to discard or rerun a session.

## 9. Sessions not yet run

No session under this corrected harness has been run as of this amendment. The
next execution sequence is No Depwire, Depwire Basic, then Depwire Guided; all
three start from `benchmark-baseline` and pass the harness guard first.

## 10. Post-run scorer correction

**Recorded:** 2026-08-17, after all three sessions completed and before results
publication.

The first scoring pass reported the same core-file miss in every arm. Audit
showed that all three implementations took `errorCode: string` as the first
`APIError` constructor parameter, passed it to `ExtendableError`, stored it
there as `readonly errorCode`, compiled cleanly, and exposed the property on
every `APIError` instance through inheritance. The validator incorrectly
required the property declaration to be physically inside the `APIError` class.

The AST validator was corrected to accept either direct readonly storage in
`APIError` or readonly storage in its base class when `APIError` passes the
first parameter through. Each frozen result-branch commit was then rescored;
no agent code, transcript, timing, tool count, test result, or branch commit was
changed. This is a scorer-bug correction, not a session rerun or exclusion.
