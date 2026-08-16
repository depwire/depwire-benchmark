# Depwire Benchmark

Reproducible benchmark comparing AI coding agent performance with and without [Depwire](https://github.com/depwire/depwire) MCP tools.

## Results withdrawn

The July results and all performance and correctness claims derived from them
have been withdrawn. An audit found three material harness defects:

1. The task prompt exposed the complete answer key.
2. The scored 81-file set excluded required monorepo consumers.
3. The no-Depwire arm started in a different working directory.

The raw records remain in `results/` for auditability, but they are not valid
evidence of a Depwire effect. Three corrected sessions have now been run with
an answer-key-free prompt, a 126-file monorepo oracle, and identical launch
conditions. See `results/REPORT.md` for the exploratory results and limitations.

## Task

**Task C — Add required parameter to core error class**

Repository: payloadcms/payload @ 1545e87

Task: Add `errorCode: string` as a required first parameter to the `APIError`
constructor and update every affected caller in the monorepo. The answer key is
kept outside the agent-visible prompt.

## How to Run

### Setup

```bash
git clone https://github.com/depwire/depwire-benchmark
cd depwire-benchmark

# Clone the test repo at the pinned commit
git clone https://github.com/payloadcms/payload repo
cd repo
git checkout 1545e8758be9a887f3f1020592b3117adb54dd5f
pnpm install
cd ..

# Parse with Depwire
cd repo/packages/payload
npm install -g depwire-cli
depwire parse .
depwire prompt --tool claude > .depwire/claude-workflow.md
cd ../../..

# Create baseline
cd repo/packages/payload
git checkout -b benchmark-baseline
git add .depwire/ depwire-output.json
git commit -m "chore: depwire artifacts"
cd ../../..
```

### Run the 3 modes

```bash
# Mode 1 — No Depwire
./scripts/run_task_c_no_depwire.sh

# Mode 2 — Depwire available, no workflow guidance
./scripts/run_task_c_depwire_basic.sh

# Mode 3 — Depwire + guided workflow prompt
./scripts/run_task_c_depwire_guided.sh
```

After each run, fill in agent/cost/quality:

```bash
./scripts/fill_manual.sh results/<branch>.json
```

### View results

```bash
./scripts/summary.sh
```

## Structure

```
depwire-benchmark/
├── tasks/
│   ├── TASK_C_PROMPT.md   # Agent-visible task; no answer key
│   ├── TASK_C_GROUND_TRUTH.txt # Hidden 126-file scoring oracle
│   └── DEPWIRE_GUIDED_WORKFLOW.md # Guidance injected only in the guided arm
├── scripts/
│   ├── measure.sh          # Automated measurement (tsc + tests + scoring)
│   ├── run_task_c_*.sh     # 3 runner scripts (one per mode)
│   ├── fill_manual.sh      # Add agent/cost/quality to JSON
│   └── summary.sh          # Print results table from JSON files
├── results/                # Your results go here (gitignored)
└── README.md
```

## Contributing

Run the benchmark with different agents (Cline, Codex, Cursor) and submit your results via PR to `results/`.

We're planning Part 2: Python benchmark (Django/FastAPI) where there's no TypeScript compiler oracle — correctness differences will be more pronounced.

## License

MIT

---

*Built by [Atef Ataya](https://github.com/atefataya) — [@atefataya](https://youtube.com/@atefataya) on YouTube*
