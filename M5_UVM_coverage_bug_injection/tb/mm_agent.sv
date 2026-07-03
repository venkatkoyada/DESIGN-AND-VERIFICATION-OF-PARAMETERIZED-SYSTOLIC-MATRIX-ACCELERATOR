// mm_agent.sv  —  UVM Agent for MM Accelerator


class mm_agent extends uvm_agent;

    //  UVM Factory Registration (component type → two constructor args) 
    `uvm_component_utils(mm_agent)

    //  Sub-component Handles 
    // Instantiate all sub-components inside agent
    mm_sequencer seqr;
    mm_driver    drv;
    mm_monitor   mon;   // kept public — env needs mon.monitor_port for TLM connect

    //  Standard UVM Constructor 
    function new(string name = "mm_agent", uvm_component parent);
        super.new(name, parent);
        `uvm_info("AGENT_CLASS", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    //  Build Phase 
    // Create UVM factory objects for all sub-components in the build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AGENT_CLASS", "Build Phase!", UVM_HIGH)

        // Create factory objects for all three sub-components
        seqr = mm_sequencer::type_id::create("seqr", this);
        drv  = mm_driver::type_id::create("drv",  this);
        mon  = mm_monitor::type_id::create("mon",  this);

        `uvm_info("AGENT_CLASS",
            "seqr, drv, mon created via UVM factory",
            UVM_HIGH)
    endfunction : build_phase

    //  Connect Phase 
    // here we declare the port to export/imp port connection.
    // There are built-in ports for driver and sequencer.
    // The connection between Sequencer and Driver is made here with TLM ports.
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("AGENT_CLASS", "Connect Phase!", UVM_HIGH)

        // Wire sequencer output export to driver input port
        // Sequence items flow: sequence → sequencer.seq_item_export → driver.seq_item_port
        drv.seq_item_port.connect(seqr.seq_item_export);

        `uvm_info("AGENT_CLASS",
            "TLM connection made: drv.seq_item_port ↔ seqr.seq_item_export",
            UVM_HIGH)
    endfunction : connect_phase

    //  Run Phase — Nothing at Agent level 
    // sub-components (driver, monitor) have their own run_phase tasks
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask : run_phase

endclass : mm_agent
