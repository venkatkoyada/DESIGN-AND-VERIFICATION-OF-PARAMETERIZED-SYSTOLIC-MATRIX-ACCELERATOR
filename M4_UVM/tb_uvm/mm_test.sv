// mm_test.sv  —  UVM Test for MM Accelerator
//
// Follows ECE-593 UVM pattern exactly:
//   - extends uvm_test
//   - `uvm_component_utils (component type, two constructor args)
//   - build_phase            : creates env via UVM factory
//   - end_of_elaboration_phase : prints UVM topology (professor: "good place for topology")
//   - connect_phase          : nothing to connect at test level
//   - run_phase              : raise_objection → sequences → drop_objection
//
// Test strategy (total = 20 transactions):
//   Phase A — 3 corner sequences (guaranteed coverage bins):
//     1. mm_zero_seq     : all-zero A     → C must be zero matrix
//     2. mm_identity_seq : identity A     → C must equal B
//     3. mm_max_seq      : all-max A & B  → accumulator overflow boundary
//   Phase B — 17 random sequences:
//     mm_test_seq × 17  : weighted random (70% normal, 30% corner via constraints)
//
// UVM_MESSAGING used throughout: `uvm_info / `uvm_error / `uvm_fatal
// UVM_LOGGING: `uvm_info with UVM_NONE for test milestones (always prints)

class mm_test extends uvm_test;

    // ── UVM Factory Registration (component type → two constructor args) ──
    `uvm_component_utils(mm_test)

    // ── Sub-component Handle ──────────────────────────────────────────────
    // Component environment 'env' is now a factory object
    mm_env env;

    // ── Sequence Handles (declared as class members per ECE-593 pattern) ──
    mm_zero_seq     zero_seq;   // corner: all-zero A
    mm_identity_seq id_seq;     // corner: identity A
    mm_max_seq      max_seq;    // corner: all-max A & B
    mm_test_seq     test_seq;   // random functional test

    // ── Test Parameters ───────────────────────────────────────────────────
    localparam int NUM_RAND_TESTS = 17; // 3 corner + 17 random = 20 total

    // ── Standard UVM Constructor ──────────────────────────────────────────
    function new(string name = "mm_test", uvm_component parent);
        super.new(name, parent);
        `uvm_info("TEST_CLASS", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    // ── Build Phase ───────────────────────────────────────────────────────
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("TEST_CLASS", "Build Phase!", UVM_HIGH)

        // Create env via UVM factory — component env is now a factory object
        env = mm_env::type_id::create("env", this);

        `uvm_info("TEST_CLASS", "env created via UVM factory", UVM_HIGH)
    endfunction : build_phase

    // ── End of Elaboration Phase ──────────────────────────────────────────
    // "Here is a good place to add topology under end_of_elaboration_phase"
    // Prints the full UVM component hierarchy for verification plan review.
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        `uvm_info("TEST_CLASS",
            "End of Elaboration Phase — UVM Testbench Topology:",
            UVM_MEDIUM)
        uvm_top.print_topology();
    endfunction : end_of_elaboration_phase

    // ── Connect Phase — nothing to connect at test level ──────────────────
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("TEST_CLASS", "Connect Phase!", UVM_HIGH)
    endfunction : connect_phase

    // ── Run Phase ─────────────────────────────────────────────────────────
    task run_phase(uvm_phase phase);
        `uvm_info("TEST_CLASS", "Run Phase!", UVM_HIGH)

        // Remember to raise and drop the objections
        phase.raise_objection(this);

        `uvm_info("TEST_CLASS",
            "\n================================================",
            UVM_NONE)
        `uvm_info("TEST_CLASS",
            "  MM ACCELERATOR UVM TEST STARTING",
            UVM_NONE)
        `uvm_info("TEST_CLASS",
            $sformatf("  Plan: 3 corner + %0d random = %0d total transactions",
                       NUM_RAND_TESTS, 3 + NUM_RAND_TESTS),
            UVM_NONE)
        `uvm_info("TEST_CLASS",
            "================================================\n",
            UVM_NONE)

        // ── Phase A: Corner Sequences — hit coverage bins deterministically ──

        `uvm_info("TEST_CLASS",
            "--- Phase A: Corner Sequences (1/3) zero-A ---",
            UVM_MEDIUM)

        // Corner 1: all-zero A — expected C must be all-zero matrix
        zero_seq = mm_zero_seq::type_id::create("zero_seq");
        zero_seq.start(env.agnt.seqr);

        `uvm_info("TEST_CLASS",
            "--- Phase A: Corner Sequences (2/3) identity-A ---",
            UVM_MEDIUM)

        // Corner 2: identity A — expected C must equal B exactly
        id_seq = mm_identity_seq::type_id::create("id_seq");
        id_seq.start(env.agnt.seqr);

        `uvm_info("TEST_CLASS",
            "--- Phase A: Corner Sequences (3/3) all-max ---",
            UVM_MEDIUM)

        // Corner 3: all-max A & B — accumulator overflow boundary test
        max_seq = mm_max_seq::type_id::create("max_seq");
        max_seq.start(env.agnt.seqr);

        `uvm_info("TEST_CLASS",
            "--- Phase A complete: 3 corner transactions done ---",
            UVM_MEDIUM)

        // ── Phase B: Random Test Sequences ────────────────────────────────

        `uvm_info("TEST_CLASS",
            $sformatf("--- Phase B: %0d Random Sequences starting ---",
                       NUM_RAND_TESTS),
            UVM_MEDIUM)

        // In run_phase, create the factory object for test_seq
        // and initiate the sequencer to send the sequence.
        // A new object is created each iteration (professor's exact pattern).
        repeat(NUM_RAND_TESTS) begin
            test_seq = mm_test_seq::type_id::create("test_seq");
            test_seq.start(env.agnt.seqr);
        end

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

        // Drop objection — UVM will proceed to check/report phases
        phase.drop_objection(this);

    endtask : run_phase

endclass : mm_test
