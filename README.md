# Design and Verification of a Parameterized Systolic Matrix Accelerator

SystemVerilog RTL design and a progressively advancing verification environment for a parameterized systolic array matrix-multiplication accelerator - from a directed self-checking testbench, through class-based coverage-driven verification, to a full UVM environment with functional coverage and a formal bug injection campaign.

Developed as a team project for ECE593 Pre Silicon verification & validation by Hanisha Dhananjaya Produtur, Nikhil Swarna, and Venkat Sai Sumanth Koyada.

## Overview
The accelerator uses a 2D array of processing elements (PEs) performing matrix multiplication via a systolic dataflow, where operands are streamed and staggered through the array and partial sums are accumulated as they propagate. The project progresses through five milestones, each advancing the verification methodology: directed testing → class-based constrained-random with coverage → UVM → UVM with coverage closure and bug injection.

Core RTL modules:
- `pe.sv` — a single processing element (multiply-accumulate unit)
- `systolic_array.sv` — the 2D array of PEs
- `input_skew.sv` — staggers/skews inputs feeding the array
- `controller.sv` — control/FSM logic for the accelerator
- `mm_accelerator_top.sv` — top-level integration module

## My Contribution
Across the project, I was responsible for the processing element (`pe.sv`) and input skew logic (`input_skew.sv`) on the RTL side, which carried through every milestone. On verification, my contributions were:
- **M2 & M3**: generator, output monitor, and environment (`mm_generator.sv`, `mm_monitor.sv`, `mm_env.sv`) for the class-based testbench
- **M4**: UVM monitor, agent, and sequence item (`mm_monitor.sv`, `mm_agent.sv`, `mm_seq_item.sv`)
- **M5**: functional coverage model (`mm_coverage.sv`), plus injecting and documenting one RTL-side bug and one UVM-environment-side bug as part of the bug injection
