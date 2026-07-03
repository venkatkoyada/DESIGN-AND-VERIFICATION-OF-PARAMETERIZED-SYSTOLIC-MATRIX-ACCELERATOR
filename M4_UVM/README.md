# Milestone 4 - Migration to UVM

## Overview
This milestone migrates the verification environment from the custom class-based testbench to a standardized UVM environment, while keeping the class-based testbench in place for comparison. This was a 3-person team project.

## My Contribution
On the RTL side, `pe.sv` and `input_skew.sv` remain my contribution. On the UVM side, I built the **monitor** (`mm_monitor.sv`), **agent** (`mm_agent.sv`), and **sequence item** (`mm_seq_item.sv`) — observing DUT outputs, assembling the agent's driver/sequencer/monitor via the UVM factory, and defining the randomized transaction packet class.

## Project Structure
```
src/      → RTL design files
tb_class/ → Class-based testbench (carried forward from M2 & M3)
tb_uvm/   → UVM testbench components
scripts/  → Makefile to run simulation
docs/     → Verification plan and simulation log
```
