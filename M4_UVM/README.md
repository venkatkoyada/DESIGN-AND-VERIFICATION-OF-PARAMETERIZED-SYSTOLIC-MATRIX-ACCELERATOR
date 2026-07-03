# Milestone 4 — Migration to UVM

## What this milestone covers
- Same RTL design, now verified with **both** the class-based testbench
  (carried over from M2/M3, kept for reference/comparison) **and** a new
  **UVM (Universal Verification Methodology) testbench**.
- This is the migration step from a custom class-based environment to a
  standardized, reusable UVM environment (agent, sequencer, driver, monitor,
  scoreboard, sequence/sequence item, virtual interface, test, top).

## Folder layout
- `src/` — RTL design files for this milestone
- `tb_class/` — the class-based testbench (carried forward from M2/M3)
- `tb_uvm/` — the new UVM testbench components
- `scripts/` — Makefile to run the UVM simulation
- `docs/` — verification plan and simulation log for this milestone

## Why this approach
UVM standardizes verification architecture (agents, sequences, factory
overrides, configuration objects) making the environment more reusable and
extensible than a hand-rolled class-based testbench. Building it alongside the
existing class-based TB in this milestone lets us verify the UVM environment
produces consistent results before fully committing to it. Milestone 5 then
builds on this UVM environment to add coverage-driven closure and a formal bug
injection campaign.
