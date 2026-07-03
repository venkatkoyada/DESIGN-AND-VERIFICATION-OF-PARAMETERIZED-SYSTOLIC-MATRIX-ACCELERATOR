// mm_sequencer.sv  —  UVM Sequencer for MM Accelerator
//
// Follows ECE-593 UVM pattern exactly:
//   - Parameterized class: extends uvm_sequencer#(mm_seq_item)
//   - `uvm_component_utils for factory registration (component type, two args)
//   - Standard UVM Constructor with (name, parent) — component type needs both
//   - Optional build_phase and connect_phase with `uvm_info logging
//   - No run_phase needed — sequencer arbitration is built into uvm_sequencer base
//
// The sequencer acts as a traffic controller between sequence and driver.
// It holds the seq_item_export TLM port that the driver connects to.
// The TLM connection: driver.seq_item_port <-> sequencer.seq_item_export
// (this connection is made inside mm_agent's connect_phase)

class mm_sequencer extends uvm_sequencer #(mm_seq_item);

    // UVM Factory Registration 
    `uvm_component_utils(mm_sequencer)

    // Standard UVM Constructor 
    function new(string name = "mm_sequencer", uvm_component parent);
        super.new(name, parent);
    endfunction : new

    // Build Phase 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("SEQR_CLASS", "Build Phase!", UVM_HIGH)
    endfunction : build_phase

    // Connect Phase 
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("SEQR_CLASS", "Connect Phase!", UVM_HIGH)
    endfunction : connect_phase

endclass : mm_sequencer
