// mm_test.sv  —  UVM Test for MM Accelerator

class mm_test extends uvm_test;

    //UVM Factory Registration 
    `uvm_component_utils(mm_test)

    mm_env env;

    
    mm_zero_seq     zero_seq;      
    mm_identity_seq id_seq;        
    mm_max_seq      max_seq;       
    mm_zero_b_seq   zero_b_seq;    
    mm_midrange_seq midrange_seq;  
    mm_test_seq     test_seq;      
    mm_error_seq    error_seq;     

    localparam int NUM_RAND_TESTS = 16;

    //UVM Log File Handle(UVM_LOGGING)
    integer logfile;

    function new(string name = "mm_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("TEST_CLASS", "Inside Constructor!", UVM_HIGH)
    endfunction : new


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TEST_CLASS", "Build Phase!", UVM_HIGH)

        // Create env via UVM factory
        env = mm_env::type_id::create("env", this);

        `uvm_info("TEST_CLASS", "env created via UVM factory", UVM_HIGH)
    endfunction : build_phase

    // End of Elaboration Phase
    // "Here is a good place to add topology under end_of_elaboration_phase"
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TEST_CLASS",
            "End of Elaboration Phase — UVM Testbench Topology:",
            UVM_MEDIUM)
        uvm_top.print_topology();
    endfunction : end_of_elaboration_phase

    //Connect Phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("TEST_CLASS", "Connect Phase!", UVM_HIGH)
    endfunction : connect_phase

    //Start of Simulation Phase
    virtual function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);

        // UVM Logging Setup
        logfile = $fopen("uvm_run.log", "w");
        if (logfile == 0)
            `uvm_fatal("TEST_CLASS", "Cannot open uvm_run.log — check directory permissions")

        //set_report_severity_action_hier(UVM_INFO,    UVM_DISPLAY | UVM_LOG);
        set_report_severity_action_hier(UVM_WARNING, UVM_DISPLAY | UVM_LOG);
        set_report_severity_action_hier(UVM_ERROR,   UVM_DISPLAY | UVM_LOG);
        set_report_severity_action_hier(UVM_FATAL,   UVM_DISPLAY | UVM_LOG);

        //set_report_severity_file_hier(UVM_INFO,    logfile);
        set_report_severity_file_hier(UVM_WARNING, logfile);
        set_report_severity_file_hier(UVM_ERROR,   logfile);
        set_report_severity_file_hier(UVM_FATAL,   logfile);

        `uvm_info("TEST_CLASS",
            "UVM Logging enabled — all messages mirrored to uvm_run.log",
            UVM_NONE)

        // ── Project Banner (ASCII art) ────────────────────────────────────
        `uvm_info("PROJECT_INFO", {
            "\n\n",
            "================================================================================\n",
            "||                                                                            ||\n",
            "||          #####  ####   #####    #####  #####  #####                      ||\n",
            "||          #      #      #        #      #   #      #                      ||\n",
            "||          ####   #      ####     #####  #####  #####                      ||\n",
            "||          #      #      #            #      #      #                      ||\n",
            "||          #####  ####   #####    #####      #  #####                      ||\n",
            "||                                                                            ||\n",
            "||   PARAMETERIZED SYSTOLIC ARRAY MATRIX MULTIPLICATION ACCELERATOR         ||\n",
            "||                                                                            ||\n",
            "||   Course    : ECE 593 - Fundamentals of Pre-Silicon Validation           ||\n",
            "||   Professor : Venkatesh Patil                                             ||\n",
            $sformatf("||   Matrix    : %0d x %0d  (Parameterized - run: make N=<value> all)        ||\n",
                `MATRIX_N, `MATRIX_N),
            "||                                                                            ||\n",
            "||   Group Members :                                                         ||\n",
            "||     [1] Nikhil Swarna                                                     ||\n",
            "||     [2] Hanisha Dhananjaya Produtur                                       ||\n",
            "||     [3] Venkat Sai Sumanth Koyada                                         ||\n",
            "||                                                                            ||\n",
            "================================================================================\n\n"
        }, UVM_NONE)
    endfunction : start_of_simulation_phase

    //Run Phase
    task run_phase(uvm_phase phase);
        `uvm_info("TEST_CLASS", "Run Phase!", UVM_HIGH)

        phase.raise_objection(this);

        `uvm_info("TEST_CLASS",
            "\n================================================",
            UVM_NONE)
        `uvm_info("TEST_CLASS",
            "  MM ACCELERATOR UVM TEST STARTING",
            UVM_NONE)
        `uvm_info("TEST_CLASS",
            $sformatf("  Plan: 5 corner + %0d random = %0d total transactions",
                       NUM_RAND_TESTS, 5 + NUM_RAND_TESTS),
            UVM_NONE)
        `uvm_info("TEST_CLASS",
            "================================================\n",
            UVM_NONE)

        //Phase A: Corner Sequences — hit coverage bins deterministically

        `uvm_info("TEST_CLASS",
            "--- Phase A: Corner Sequences (1/5) zero-A ---",
            UVM_MEDIUM)

        // Corner 1: all-zero A — expected C must be all-zero matrix
        zero_seq = mm_zero_seq::type_id::create("zero_seq");
        zero_seq.start(env.agnt.seqr);

        `uvm_info("TEST_CLASS",
            "--- Phase A: Corner Sequences (2/5) identity-A ---",
            UVM_MEDIUM)

        // Corner 2: identity A — expected C must equal B exactly
        id_seq = mm_identity_seq::type_id::create("id_seq");
        id_seq.start(env.agnt.seqr);

        `uvm_info("TEST_CLASS",
            "--- Phase A: Corner Sequences (3/5) all-max ---",
            UVM_MEDIUM)

        // Corner 3: all-max A & B — accumulator overflow boundary test
        max_seq = mm_max_seq::type_id::create("max_seq");
        max_seq.start(env.agnt.seqr);

        `uvm_info("TEST_CLASS",
            "--- Phase A: Corner Sequences (4/5) zero-B ---",
            UVM_MEDIUM)

        // Corner 4: random A, all-zero B — guarantees cg_b_vals.zero coverage bin
        zero_b_seq = mm_zero_b_seq::type_id::create("zero_b_seq");
        zero_b_seq.start(env.agnt.seqr);

        `uvm_info("TEST_CLASS",
            "--- Phase A: Corner Sequences (5/5) mid-range ---",
            UVM_MEDIUM)

        // Corner 5: A[0][0]=2 B[0][0]=128 all others 0
        // C[0][0] = 2x128 = 256 in mid_range [256:65535] for any N
        midrange_seq = mm_midrange_seq::type_id::create("midrange_seq");
        midrange_seq.start(env.agnt.seqr);

        `uvm_info("TEST_CLASS",
            "--- Phase A complete: 5 corner transactions done ---",
            UVM_MEDIUM)

        //Phase B: Random Test Sequences

        `uvm_info("TEST_CLASS",
            $sformatf("--- Phase B: %0d Random Sequences starting ---",
                       NUM_RAND_TESTS),
            UVM_MEDIUM)

        // BUG4: swap in mm_error_seq — reference model uses A+B instead of A×B,
        // causing uvm_error for every non-zero transaction result.
`ifdef BUG4
        repeat(NUM_RAND_TESTS) begin
            error_seq = mm_error_seq::type_id::create("error_seq");
            error_seq.start(env.agnt.seqr);
        end
`else
        repeat(NUM_RAND_TESTS) begin
            test_seq = mm_test_seq::type_id::create("test_seq");
            test_seq.start(env.agnt.seqr);
        end
`endif

        `uvm_info("TEST_CLASS",
            "--- Phase B complete: all random sequences done ---",
            UVM_MEDIUM)

        `uvm_info("TEST_CLASS",
            "\n================================================",
            UVM_NONE)
        `uvm_info("TEST_CLASS",
            "  MM ACCELERATOR UVM TEST COMPLETE",
            UVM_NONE)
        `uvm_info("TEST_CLASS",
            "  Dropping objection — UVM will proceed to report_phase",
            UVM_NONE)
        `uvm_info("TEST_CLASS",
            "================================================\n",
            UVM_NONE)

        // Drop objection
        phase.drop_objection(this);

    endtask : run_phase

endclass : mm_test
