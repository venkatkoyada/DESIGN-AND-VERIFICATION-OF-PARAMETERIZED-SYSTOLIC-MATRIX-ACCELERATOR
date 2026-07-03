// mm_driver.sv  —  UVM Driver for MM Accelerator
class mm_driver extends uvm_driver #(mm_seq_item);

    // UVM Factory Registration (component type → two constructor args) 
    `uvm_component_utils(mm_driver)

    //  Virtual Interface Handle 
    // Driver interacts with DUT, hence we need the virtual interface
    virtual mm_uvm_if vif;

    //  Fixed Parameters matching DUT mm_accelerator_top — N set by make N=<val>
    localparam int N          = `MATRIX_N;
    localparam int DATA_WIDTH = 8;

    //  Standard UVM Constructor (component — two arguments) 
    function new(string name = "mm_driver", uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //  Build Phase 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("DRIVER_CLASS", "Build Phase!", UVM_HIGH)

        // Get virtual interface pointer from the centralized config_db
        // Set in tb_top: uvm_config_db#(virtual mm_uvm_if)::set(null,"*","vif",intf)
        if (!uvm_config_db #(virtual mm_uvm_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRIVER_CLASS",
                "Failed to get virtual mm_uvm_if from config DB. Check tb_top set() call.")
    endfunction : build_phase

    //  Run Phase 
    task run_phase(uvm_phase phase);
        `uvm_info("DRIVER_CLASS", "Run Phase!", UVM_HIGH)

        // Apply DUT reset once before processing any sequence items
        apply_reset();

        // Standard UVM driver loop
        forever begin
            // Fetch next sequence item from sequencer
            seq_item_port.get_next_item(req);

            `uvm_info("DRIVER_CLASS",
                $sformatf("Received seq_item — corner_mode=%0d  Driving DUT...",
                           req.corner_mode),
                UVM_MEDIUM)

            // Drive the full protocol for this transaction
            drive_transaction(req);

            // Signal sequencer: driver is done with this item
            // Called AFTER result_valid so monitor has captured the output
            seq_item_port.item_done();

            `uvm_info("DRIVER_CLASS", "item_done() — ready for next seq_item", UVM_HIGH)
        end
    endtask : run_phase

    // apply_reset: drives rst_n=0 for 5 cycles then releases
    
    task apply_reset();
        `uvm_info("DRIVER_CLASS", "Asserting reset (5 cycles)...", UVM_MEDIUM)

        vif.rst_n             = 1'b0;
        vif.start             = 1'b0;
        vif.a_in              = '0;
        vif.b_in              = '0;
        vif.valid_in_upstream = 1'b0;

        repeat(5) @(posedge vif.clk);

        @(posedge vif.clk); #1;
        vif.rst_n = 1'b1;

        repeat(2) @(posedge vif.clk);

        `uvm_info("DRIVER_CLASS", "Reset released — DUT initialised", UVM_MEDIUM)
    endtask : apply_reset

    //  drive_transaction: full DUT protocol for one N×N matrix multiply
   
    task drive_transaction(mm_seq_item txn);

        `uvm_info("DRIVER_CLASS",
            $sformatf("--- Transaction start: corner_mode=%0d ---", txn.corner_mode),
            UVM_HIGH)

        // Step 1: Assert start pulse for 1 cycle 
        @(posedge vif.clk); #1;
        vif.start = 1'b1;
        `uvm_info("DRIVER_CLASS", "start=1 asserted", UVM_HIGH)

        @(posedge vif.clk); #1;
        vif.start = 1'b0;
        `uvm_info("DRIVER_CLASS", "start=0 de-asserted", UVM_HIGH)

        // Step 2: Wait for controller ready (enters LOAD state) 
        wait(vif.ready == 1'b1);
        `uvm_info("DRIVER_CLASS",
            "ready=1 — controller in LOAD state, beginning data drive", UVM_HIGH)

        // Step 3: Drive N cycles of matrix data 
        // Cycle k: a_in = column k of A (a_in[r*DW+:DW] = A[r][k])
        //          b_in = row    k of B (b_in[c*DW+:DW] = B[k][c])
        for (int k = 0; k < N; k++) begin
            @(posedge vif.clk); #1;
            vif.a_in              = pack_col_a(txn.A, k);
            vif.b_in              = pack_row_b(txn.B, k);
            vif.valid_in_upstream = 1'b1;

            `uvm_info("DRIVER_CLASS",
                $sformatf("  k=%0d: a_in=0x%0h  b_in=0x%0h  valid=1",
                           k, vif.a_in, vif.b_in),
                UVM_HIGH)
        end

        // Step 4: De-assert valid_in_upstream — data phase complete
        @(posedge vif.clk); #1;
        vif.valid_in_upstream = 1'b0;
        vif.a_in              = '0;
        vif.b_in              = '0;
        `uvm_info("DRIVER_CLASS",
            "valid_in_upstream=0 — data phase done, waiting for result_valid",
            UVM_MEDIUM)

        // Step 5: Wait for DUT to pulse result_valid (DONE state) 
        wait(vif.result_valid == 1'b1);
        `uvm_info("DRIVER_CLASS",
            "result_valid=1 — DUT in DONE state, transaction complete",
            UVM_MEDIUM)

        // Allow result_valid pulse to clear (DUT returns to IDLE)
        @(posedge vif.clk); #1;

        `uvm_info("DRIVER_CLASS",
            "--- Transaction end: DUT returned to IDLE ---",
            UVM_HIGH)

    endtask : drive_transaction

    // pack_col_a: pack column col_idx of mat into flat [N*DW-1:0] bus
    //   a_in[r*DW +: DW] = A[r][col_idx]   for r = 0..N-1
    
    function automatic logic [N*DATA_WIDTH-1:0] pack_col_a(
        input logic [DATA_WIDTH-1:0] mat     [N][N],
        input int                    col_idx
    );
        logic [N*DATA_WIDTH-1:0] bus;
        for (int r = 0; r < N; r++)
            bus[r*DATA_WIDTH +: DATA_WIDTH] = mat[r][col_idx];
        return bus;
    endfunction : pack_col_a

    // pack_row_b: pack row row_idx of mat into flat [N*DW-1:0] bus
    //   b_in[c*DW +: DW] = B[row_idx][c]   for c = 0..N-1
   
    function automatic logic [N*DATA_WIDTH-1:0] pack_row_b(
        input logic [DATA_WIDTH-1:0] mat     [N][N],
        input int                    row_idx
    );
        logic [N*DATA_WIDTH-1:0] bus;
        for (int c = 0; c < N; c++)
            bus[c*DATA_WIDTH +: DATA_WIDTH] = mat[row_idx][c];
        return bus;
    endfunction : pack_row_b

endclass : mm_driver
