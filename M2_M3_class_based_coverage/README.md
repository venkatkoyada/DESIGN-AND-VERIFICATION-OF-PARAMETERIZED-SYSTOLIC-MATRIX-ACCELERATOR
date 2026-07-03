# Milestone 2 & 3 - Class-Based Testbench with Functional Coverage

## Overview
Building on the Milestone 1 RTL, this milestone replaces the directed testbench with a class-based, constrained-random verification environment (transaction, generator, driver, monitor, scoreboard, and coverage collector). This was a 3-person team project.

## My Contribution
On the RTL side, `pe.sv` and `input_skew.sv` remain my contribution from Milestone 1. On the verification side, I contributed the **generator**, **output monitor**, and **environment** (`mm_generator.sv`, `mm_monitor.sv`, `mm_env.sv`) — roughly a third of this milestone's testbench work — handling randomized stimulus generation, output observation, and environment integration.

## Project Structure
```
src/      → RTL design files
tb/       → Class-based testbench (transaction, generator, driver, monitor, scoreboard, coverage, interface, top)
scripts/  → Makefiles to run simulation
docs/     → Design spec, verification plan, milestone report, sim transcript, coverage_reports/
```
