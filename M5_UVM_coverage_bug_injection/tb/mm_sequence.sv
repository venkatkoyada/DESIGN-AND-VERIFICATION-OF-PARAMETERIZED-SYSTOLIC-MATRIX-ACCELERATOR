// mm_sequence.sv  —  UVM Sequences for MM Accelerator
class mm_base_seq extends uvm_sequence #(mm_seq_item);

    // UVM factory registration — sequence is object type
    `uvm_object_utils(mm_base_seq)

    // Handle for the sequence item (packet)
    mm_seq_item item;

    // Standard UVM Constructor
    function new(string name = "mm_base_seq");
        super.new(name);
        `uvm_info("BASE_SEQ", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    // Body Task — sequence is object class, hence no UVM phases
    task body();
        `uvm_info("BASE_SEQ", "Inside body task!", UVM_HIGH)

        // Create factory object so it can be randomized
        item = mm_seq_item::type_id::create("item");

        start_item(item);                           // request access from sequencer
        void'(item.randomize());                    // randomize — post_randomize() auto-called
        `uvm_info("BASE_SEQ",
            $sformatf("Generated transaction:%s", item.convert2string()),
            UVM_HIGH)
        finish_item(item);                          // send to driver, block until item_done()

    endtask : body

endclass : mm_base_seq


//  TEST SEQUENCE  —  inherits mm_base_seq; fully random, weighted corners
class mm_test_seq extends mm_base_seq;

    // UVM factory registration
    `uvm_object_utils(mm_test_seq)

    // Handle for the sequence item
    mm_seq_item item;

    // Standard UVM Constructor
    function new(string name = "mm_test_seq");
        super.new(name);
        `uvm_info("TEST_SEQ", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    // Body Task — randomize inputs when DUT is running normally
    task body();
        `uvm_info("TEST_SEQ", "Inside body task!", UVM_HIGH)

        // Create factory object for the transaction
        item = mm_seq_item::type_id::create("item");

        start_item(item);
        // Randomize — corner_mode weighted by c_corner_dist (70/10/10/10)
        void'(item.randomize());
        `uvm_info("TEST_SEQ",
            $sformatf("Sending transaction (corner_mode=%0d):%s",
                       item.corner_mode, item.convert2string()),
            UVM_MEDIUM)
        finish_item(item);

    endtask : body

endclass : mm_test_seq


//  CORNER SEQUENCE: ALL-ZERO A  (corner_mode = 1)
class mm_zero_seq extends mm_base_seq;

    `uvm_object_utils(mm_zero_seq)

    mm_seq_item item;

    function new(string name = "mm_zero_seq");
        super.new(name);
        `uvm_info("ZERO_SEQ", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    task body();
        `uvm_info("ZERO_SEQ", "Inside body task! — corner: all-zero A", UVM_HIGH)

        item = mm_seq_item::type_id::create("item");

        start_item(item);
        // Force corner_mode=1 so post_randomize() sets all A to zero
        void'(item.randomize() with { corner_mode == 2'b01; });
        `uvm_info("ZERO_SEQ",
            $sformatf("Sending zero-A corner:%s", item.convert2string()),
            UVM_MEDIUM)
        finish_item(item);

    endtask : body

endclass : mm_zero_seq


//  CORNER SEQUENCE: IDENTITY A  (corner_mode = 2)
// Expected: C must equal B
class mm_identity_seq extends mm_base_seq;

    `uvm_object_utils(mm_identity_seq)

    mm_seq_item item;

    function new(string name = "mm_identity_seq");
        super.new(name);
        `uvm_info("IDENTITY_SEQ", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    task body();
        `uvm_info("IDENTITY_SEQ", "Inside body task! — corner: identity A", UVM_HIGH)

        item = mm_seq_item::type_id::create("item");

        start_item(item);
        // Force corner_mode=2 so post_randomize() sets A = identity matrix.
        // Constrain B[0][0]≥1 so C[0][0]=B[0][0]∈[1:255] → guaranteed lo_range hit for any N.
        void'(item.randomize() with { corner_mode == 2'b10; B[0][0] inside {[8'h01:8'hFF]}; });
        `uvm_info("IDENTITY_SEQ",
            $sformatf("Sending identity-A corner:%s", item.convert2string()),
            UVM_MEDIUM)
        finish_item(item);

    endtask : body

endclass : mm_identity_seq


//  CORNER SEQUENCE: ALL-MAX A & B  (corner_mode = 3)
// Expected: tests accumulator overflow boundary
class mm_max_seq extends mm_base_seq;

    `uvm_object_utils(mm_max_seq)

    mm_seq_item item;

    function new(string name = "mm_max_seq");
        super.new(name);
        `uvm_info("MAX_SEQ", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    task body();
        `uvm_info("MAX_SEQ", "Inside body task! — corner: all-max A & B", UVM_HIGH)

        item = mm_seq_item::type_id::create("item");

        start_item(item);
        // Force corner_mode=3 so post_randomize() sets A=B=0xFF
        void'(item.randomize() with { corner_mode == 2'b11; });
        `uvm_info("MAX_SEQ",
            $sformatf("Sending all-max corner:%s", item.convert2string()),
            UVM_MEDIUM)
        finish_item(item);

    endtask : body

endclass : mm_max_seq

// CORNER SEQUENCE: ALL-ZERO B  (coverage-directed — guarantees B=zero bin)
// A is randomized normally; B is forced to 8'h00 after randomize().
// compute_expected() is called to recompute C = A × 0 = zero matrix.
// corner_mode = 0 (rand_mode) so the mode distribution is unaffected.

class mm_zero_b_seq extends mm_base_seq;

    `uvm_object_utils(mm_zero_b_seq)

    mm_seq_item item;

    function new(string name = "mm_zero_b_seq");
        super.new(name);
        `uvm_info("ZERO_B_SEQ", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    task body();
        `uvm_info("ZERO_B_SEQ", "Inside body task! — coverage: all-zero B", UVM_HIGH)

        item = mm_seq_item::type_id::create("item");

        start_item(item);
        // Randomize with rand_mode so A stays random (corner_mode=0)
        void'(item.randomize() with { corner_mode == 2'b00; });
        // Force all B elements to zero — explicit loops (VCS-safe, no foreach on handle)
        for (int r = 0; r < `MATRIX_N; r++)
            for (int c = 0; c < `MATRIX_N; c++)
                item.B[r][c] = 8'h00;
        // Recompute C = A × B (now all zeros since B = 0) in ref model
        item.compute_expected();
        `uvm_info("ZERO_B_SEQ",
            $sformatf("Sending zero-B coverage txn:%s", item.convert2string()),
            UVM_MEDIUM)
        finish_item(item);

    endtask : body

endclass : mm_zero_b_seq

// CORNER SEQUENCE: MID-RANGE RESULT  (coverage-directed — guarantees mid_range)

class mm_midrange_seq extends mm_base_seq;

    `uvm_object_utils(mm_midrange_seq)

    mm_seq_item item;

    function new(string name = "mm_midrange_seq");
        super.new(name);
        `uvm_info("MIDRANGE_SEQ", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    task body();
        `uvm_info("MIDRANGE_SEQ",
            "Inside body task! — coverage: mid-range C result (any N)", UVM_HIGH)

        item = mm_seq_item::type_id::create("item");

        start_item(item);
        void'(item.randomize() with { corner_mode == 2'b00; });

        // Zero out all A and B — explicit loops (VCS-safe)
        for (int r = 0; r < `MATRIX_N; r++)
            for (int c = 0; c < `MATRIX_N; c++) begin
                item.A[r][c] = 8'h00;
                item.B[r][c] = 8'h00;
            end

        // Single nonzero product: A[0][0]=2, B[0][0]=128
        // C[0][0] = 2 x 128 = 256  in mid_range [256:65535] for any N
        item.A[0][0] = 8'd2;
        item.B[0][0] = 8'd128;
        item.compute_expected();

        `uvm_info("MIDRANGE_SEQ",
            $sformatf("Sending mid-range coverage txn:%s", item.convert2string()),
            UVM_MEDIUM)
        finish_item(item);

    endtask : body

endclass : mm_midrange_seq


// ERROR SEQUENCE  (BUG4 — activated by +define+BUG4)

class mm_error_seq extends mm_base_seq;

    `uvm_object_utils(mm_error_seq)

    mm_seq_item item;

    function new(string name = "mm_error_seq");
        super.new(name);
        `uvm_info("ERROR_SEQ", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    task body();
        `uvm_info("ERROR_SEQ",
            "Inside body — BUG4 active: reference model uses A+B instead of A*B",
            UVM_MEDIUM)

        item = mm_seq_item::type_id::create("item");

        start_item(item);
        // Fully random stimulus — the bug is in compute_expected(), not the data
        void'(item.randomize() with { corner_mode == 2'b00; });
        `uvm_info("ERROR_SEQ",
            $sformatf("Sending error-seq transaction:%s", item.convert2string()),
            UVM_MEDIUM)
        finish_item(item);

    endtask : body

endclass : mm_error_seq
