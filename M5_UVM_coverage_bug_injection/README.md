# Milestone 5 - UVM, Functional Coverage & Bug Injection Campaign

## Overview
The final milestone verifies the completed RTL design using a full UVM testbench with functional coverage collection, followed by a formal bug injection campaign to validate the verification environment's effectiveness. This was a 3-person team project.

## My Contribution
On the RTL side, `pe.sv` and `input_skew.sv` remain my contribution. On the UVM side, I built the **monitor**, **agent**, and **sequence item** (carried forward from Milestone 4), and added the **functional coverage model** (`mm_coverage.sv`) for this milestone. For the bug injection campaign, I was responsible for injecting and documenting one RTL-side bug and one verification-environment-side (UVM) bug, confirming both were correctly detected by the testbench.

## Project Structure
```
src/      → Final RTL design files
tb/       → Full UVM testbench (agent, driver, monitor, scoreboard, coverage, sequence, sequencer, seq_item, interface, test, top)
scripts/  → Makefile to run simulation
docs/     → Design spec, verification plan, sim/UVM logs, coverage_reports/, bug_injection_reports/, project presentation
waveforms/→ Waveform screenshot from simulation
```
