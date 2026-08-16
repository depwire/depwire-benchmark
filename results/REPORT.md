# July 2026 Task C Runs — Withdrawn Results

The comparative conclusions previously reported in this file are withdrawn.

The underlying run artifacts are retained in this directory for auditability,
but the runs are not comparable because:

- every agent-visible prompt contained the complete 81-file answer key and the
  exact error code for each subclass;
- the 81-file scoring set excluded required consumers elsewhere in the
  monorepo, even though agents had to update those consumers to complete the
  requested change and pass the required test command;
- the no-Depwire arm lost time recovering from a different starting directory;
- each arm had only one run.

Consequently, the old records do not measure discovery correctness and their
timing, token, API-call, and cost differences cannot be attributed to Depwire.
All three arms must be rerun under the corrected harness before a new result is
reported.
