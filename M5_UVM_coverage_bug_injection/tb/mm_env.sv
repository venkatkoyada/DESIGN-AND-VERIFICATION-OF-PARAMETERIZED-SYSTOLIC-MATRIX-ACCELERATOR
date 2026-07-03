// mm_env.sv  —  UVM Environment for MM Accelerator

class mm_env extends uvm_env;

    // UVM Factory Registration (component type → two constructor args)
    `uvm_component_utils(mm_env)

    // Sub-component Handles
    // Environment contains agent, scoreboard, and coverage subscriber
    mm_agent      agnt;
    mm_scoreboard scb;
    mm_coverage   cov;

    // Standard UVM Constructor
    function new(string name = "mm_env", uvm_component parent);
        super.new(name, parent);
        `uvm_info("ENV_CLASS", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    //  Build Phase
    // Create the sub-components using UVM factory create method
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("ENV_CLASS", "Build Phase!", UVM_HIGH)

        // Create factory objects for the sub-components
        agnt = mm_agent::type_id::create("agnt", this);
        scb  = mm_scoreboard::type_id::create("scb",  this);
        cov  = mm_coverage::type_id::create("cov",  this);

        `uvm_info("ENV_CLASS",
            "agnt, scb, and cov created via UVM factory",
            UVM_HIGH)
    endfunction : build_phase

    //  Connect Phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("ENV_CLASS", "Connect Phase!", UVM_HIGH)

        // Connect monitor analysis port to scoreboard (uvm_analysis_imp)
        agnt.mon.monitor_port.connect(scb.scoreboard_port);
        // Fan-out: same port also drives coverage subscriber (built-in analysis_export)
        agnt.mon.monitor_port.connect(cov.analysis_export);

        `uvm_info("ENV_CLASS",
            "TLM connections made: monitor_port → scb.scoreboard_port + cov.analysis_export",
            UVM_HIGH)
    endfunction : connect_phase

    //  Run Phase
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask : run_phase

endclass : mm_env
