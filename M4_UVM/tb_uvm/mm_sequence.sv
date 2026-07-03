// mm_sequence.sv  —  UVM Sequences for MM Accelerator
//
// Follows ECE-593 UVM pattern exactly:
//   mm_base_seq    : base class — one random item (inheritable)
//   mm_test_seq    : inherits mm_base_seq — fully random functional test
//   mm_zero_seq    : inherits mm_base_seq — corner: all-zero A  (corner_mode=1)
//   mm_identity_seq: inherits mm_base_seq — corner: identity A  (corner_mode=2)
//   mm_max_seq     : inherits mm_base_seq — corner: all-max A&B (corner_mode=3)
//
// All sequences:
//   - `uvm_object_utils  (sequence is object type → ONE argument)
//   - mm_seq_item::type_id::create() via UVM factory
//   - start_item() / finish_item() handshake with sequencer
//   - `uvm_info UVM_MESSAGING for logging every item generated
//
// NOTE: Driver handles reset independently at run_phase startup.
//       Sequences ONLY generate stimulus transactions.

// ─────────────────────────────────────────────────────────────────────────────
// BASE SEQUENCE  —  one random transaction; other sequences inherit from this
// ─────────────────────────────────────────────────────────────────────────────
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


// ─────────────────────────────────────────────────────────────────────────────
// TEST SEQUENCE  —  inherits mm_base_seq; fully random, weighted corners
// ─────────────────────────────────────────────────────────────────────────────
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


// ─────────────────────────────────────────────────────────────────────────────
// CORNER SEQUENCE: ALL-ZERO A  (corner_mode = 1)
// Expected: C must equal zero matrix
// ─────────────────────────────────────────────────────────────────────────────
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


// ─────────────────────────────────────────────────────────────────────────────
// CORNER SEQUENCE: IDENTITY A  (corner_mode = 2)
// Expected: C must equal B
// ─────────────────────────────────────────────────────────────────────────────
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
        // Force corner_mode=2 so post_randomize() sets A = identity matrix
        void'(item.randomize() with { corner_mode == 2'b10; });
        `uvm_info("IDENTITY_SEQ",
            $sformatf("Sending identity-A corner:%s", item.convert2string()),
            UVM_MEDIUM)
        finish_item(item);

    endtask : body

endclass : mm_identity_seq


// ─────────────────────────────────────────────────────────────────────────────
// CORNER SEQUENCE: ALL-MAX A & B  (corner_mode = 3)
// Expected: tests accumulator overflow boundary
// ─────────────────────────────────────────────────────────────────────────────
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
