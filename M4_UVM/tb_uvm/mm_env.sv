// mm_env.sv  —  UVM Environment for MM Accelerator
//
// Follows ECE-593 UVM pattern exactly:
//   - extends uvm_env
//   - `uvm_component_utils (component type, two constructor args)
//   - build_phase   : creates agent and scoreboard via UVM factory (type_id::create)
//   - connect_phase : wires monitor analysis port → scoreboard analysis imp
//   - run_phase     : nothing at env level (sub-components have their own run_phase)
//
// UVM Hierarchy under env:
//   mm_env
//   ├── mm_agent  agnt
//   │     ├── mm_sequencer seqr
//   │     ├── mm_driver    drv
//   │     └── mm_monitor   mon
//   └── mm_scoreboard scb
//
// TLM connection made here (professor: "Do the TLM port connections
// between Monitor and Scoreboard"):
//   agnt.mon.monitor_port  ──→  scb.scoreboard_port
//   (uvm_analysis_port)         (uvm_analysis_imp)

class mm_env extends uvm_env;

    // ── UVM Factory Registration (component type → two constructor args) ──
    `uvm_component_utils(mm_env)

    // ── Sub-component Handles ─────────────────────────────────────────────
    // Environment contains agent and scoreboard — instantiate the components
    mm_agent      agnt;
    mm_scoreboard scb;

    // ── Standard UVM Constructor ──────────────────────────────────────────
    function new(string name = "mm_env", uvm_component parent);
        super.new(name, parent);
        `uvm_info("ENV_CLASS", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    // ── Build Phase ───────────────────────────────────────────────────────
    // Create the sub-components using UVM factory create method
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("ENV_CLASS", "Build Phase!", UVM_HIGH)

        // Create factory objects for the sub-components
        agnt = mm_agent::type_id::create("agnt", this);
        scb  = mm_scoreboard::type_id::create("scb",  this);

        `uvm_info("ENV_CLASS",
            "agnt and scb created via UVM factory",
            UVM_HIGH)
    endfunction : build_phase

    // ── Connect Phase ─────────────────────────────────────────────────────
    // Do the TLM port connections between Monitor and Scoreboard.
    // agnt.mon.monitor_port  is a uvm_analysis_port  (broadcasts via write())
    // scb.scoreboard_port    is a uvm_analysis_imp   (receives via write())
    // After connect: every monitor_port.write(item) automatically calls
    // scb.write(item), placing the transaction into the scoreboard queue.
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("ENV_CLASS", "Connect Phase!", UVM_HIGH)

        // Connect the export to the analysis port of monitor
        agnt.mon.monitor_port.connect(scb.scoreboard_port);

        `uvm_info("ENV_CLASS",
            "TLM connection made: agnt.mon.monitor_port → scb.scoreboard_port",
            UVM_HIGH)
    endfunction : connect_phase

    // ── Run Phase — nothing at env level ─────────────────────────────────
    // Agent sub-components (driver, monitor) and scoreboard have their own
    // run_phase tasks which UVM launches automatically in parallel.
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask : run_phase

endclass : mm_env
