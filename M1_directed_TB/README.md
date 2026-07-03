# Milestone 1 — RTL + Directed (Self-Checking) Testbench

## What this milestone covers
- Initial RTL implementation of the systolic array matrix-multiplication accelerator.
- A **traditional, directed, self-checking testbench** — fixed input stimulus with
  hardcoded expected outputs, no randomization or functional coverage.

## Folder layout
- `src/` — RTL design files (`pe.sv`, `systolic_array.sv`, `controller.sv`, `input_skew.sv`, `mm_accelerator_top.sv`)
- `tb/` — directed self-checking testbench
- `scripts/` — Makefile to run the simulation
- `docs/` — design specification and verification plan for this milestone

## Why this approach
Directed testing is the simplest way to sanity-check a new design: known inputs,
known expected outputs, pass/fail comparison. It's fast to write but doesn't scale —
it only catches bugs on the specific cases you thought to test. That limitation is
exactly what Milestone 2/3 addresses by moving to class-based, randomized,
coverage-driven verification.
