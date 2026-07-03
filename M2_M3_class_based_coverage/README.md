# Milestone 2 & 3 — Class-Based Testbench with Functional Coverage

## What this milestone covers
- Same RTL design, now verified with a **class-based, constrained-random
  testbench** (transaction, generator, driver, monitor, scoreboard, coverage
  collector — OOP-style, pre-UVM).
- **Functional coverage** is added to measure how thoroughly the verification
  space (input combinations, corner cases) has actually been exercised, instead
  of just relying on a fixed set of directed tests.

## Folder layout
- `src/` — RTL design files for this milestone
- `tb/` — class-based testbench components (transaction, generator, driver, monitor, scoreboard, coverage, interface, top)
- `scripts/` — Makefiles to run the class-based simulation
- `docs/` — design spec, verification plan, milestone report, simulation transcript, and coverage reports (`coverage_reports/`)

## Why this approach
Moving from directed to class-based verification lets the testbench generate
**randomized, constrained stimulus** rather than a fixed set of hand-picked
vectors, and the scoreboard self-checks results automatically. Functional
coverage tells us which scenarios have actually been hit, closing the gap left
by Milestone 1's directed-only approach. This class-based architecture is also
the direct stepping stone to the UVM testbench built in Milestone 4.
