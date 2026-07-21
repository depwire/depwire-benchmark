# Depwire Benchmark

Reproducible benchmark comparing AI coding agent performance with and without [Depwire](https://github.com/depwire/depwire) MCP tools.

## Results

Tested on [payloadcms/payload](https://github.com/payloadcms/payload) — 645 files, 9,292 symbols, 3-mode comparison using Claude Code (claude-opus-4-8).

| Mode | Duration | API Calls | Tokens | Cost | Score |
|------|----------|-----------|--------|------|-------|
| No Depwire | 16m 46s | 40 | 2,959,169 | $9.03 | 100% |
| Depwire (no guidance) | 11m 20s | 46 | 3,399,822 | $9.80 | 100% |
| Depwire + workflow | **10m 43s** | **26** | **2,165,356** | **$7.35** | 100% |

**Depwire + guided workflow vs no Depwire:**
- 36% faster
- 35% fewer API calls
- 27% fewer tokens
- 19% lower cost

## Task

**Task C — Add required parameter to core error class**

Repository: payloadcms/payload @ 1545e87

Task: Add `errorCode: string` as a required first parameter to the `APIError` constructor. Update ALL callers — 27 subclasses (via `super()`) + 52 direct instantiations = 80 files.

**Why this tests Depwire:**

| Method | Files Found |
|--------|-------------|
| Naive grep (`new APIError(`) | 52 |
| Smart grep (+ `extends APIError`) | 79 |
| `depwire affected_files` | 84 |

The 27 error subclasses use `super()` not `new APIError()` — naive grep misses them entirely. Depwire's graph traversal finds them all.

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

## Key Finding

Depwire without workflow guidance performed worse than no Depwire — agents had the tools but didn't use them unprompted, paying MCP overhead without getting any benefit. The `affected_files` command returned the complete 84-file blast radius in one call, but only when the agent was explicitly told to run it first.

This is why we built `depwire prompt` — not as boilerplate, but because the benchmark showed agents need an explicit decision tree to use graph tools effectively.

```bash
depwire prompt --tool claude
```

## Structure

```
depwire-benchmark/
├── tasks/
│   └── TASK_C.md          # Full task definition + ground truth
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
