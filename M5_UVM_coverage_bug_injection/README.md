# Milestone 5 — UVM, Functional Coverage & Bug Injection Campaign

## What this milestone covers
- Final RTL design, verified with a complete **UVM testbench** including
  **functional coverage** collection (`mm_coverage.sv`, `cm_hier.cfg`).
- A formal **bug injection campaign**: four bugs (BUG1–BUG4) were deliberately
  injected into the design, and the UVM testbench + coverage model were used to
  detect and diagnose each one — demonstrating the verification environment's
  effectiveness at catching real defects, not just passing clean RTL.

## Folder layout
- `src/` — final RTL design files
- `tb/` — full UVM testbench (agent, driver, monitor, scoreboard, coverage, sequence, sequencer, seq_item, virtual interface, test, top)
- `scripts/` — Makefile to run simulation
- `docs/` — design specification, verification plan, simulation/UVM run logs
  - `coverage_reports/` — functional coverage dashboard and group reports
  - `bug_injection_reports/` — per-bug simulation and UVM run logs for BUG1–BUG4, plus `BUG_REPORT.pdf` summarizing the campaign
  - project presentation (`Systolic_Array_Accelerator.pptx`)
- `waveforms/` — waveform screenshot from simulation

## Why this approach
Coverage tells you *what* you've tested; bug injection tells you *whether your
testbench actually works*. Deliberately inserting known bugs and confirming
the UVM environment catches every one of them is a standard way to validate
verification quality — if a testbench can't catch an injected bug, it likely
can't catch a real one either. This milestone represents the completed
verification flow: directed → class-based/coverage → UVM → UVM +
coverage-driven bug detection.
