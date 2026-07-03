# Milestone 1 - RTL + Directed (Self-Checking) Testbench

## Overview
This milestone covers the initial RTL implementation of a parameterized systolic array matrix-multiplication accelerator, verified using a directed, self-checking testbench. This was a 3-person team project. The design uses a 2D array of processing elements (PEs) to perform matrix multiplication via a systolic dataflow, with staggered input skewing and FSM-based control.

## My Contribution
I designed the RTL for the processing element (`pe.sv`) — the MAC datapath, pass-through logic, valid pipeline, and clear behavior — and the input skew logic (`input_skew.sv`), implementing the parameterized shift-register skew chains that stagger inputs into the array. These modules carry forward into every subsequent milestone.

## Project Structure
```
src/      → RTL design files
tb/       → Directed, self-checking testbench
scripts/  → Makefile to run simulation
docs/     → Design specification and verification plan
```
