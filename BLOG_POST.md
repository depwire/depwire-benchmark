# Depwire Agent Benchmark — Results Withdrawn

The article previously drafted here has been withdrawn and must not be
published.

An audit found that the task prompt contained the complete answer key, the
scored ground truth omitted required monorepo consumers, and one comparison arm
started in a different working directory. Those defects prevent the recorded
timing, cost, token, and correctness differences from being attributed to
Depwire.

The benchmark will be rerun from scratch with:

- one answer-key-free prompt shared by all three arms;
- one enforced working directory and pinned tool versions;
- a monorepo-wide hidden ground truth aligned with the required passing tests;
- all three arms rerun under the repaired harness.

No earlier comparative result should be cited.
