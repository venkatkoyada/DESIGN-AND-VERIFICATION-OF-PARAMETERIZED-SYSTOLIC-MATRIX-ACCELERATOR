// mm_driver.sv  —  Driver Class
//
// Receives mm_transaction objects from generator mailbox and
// drives DUT signals via a virtual interface.
//
// Protocol:
//   1. Assert start for 1 cycle to begin transaction
//   2. Wait for ready from controller
//   3. Drive N cycles of A/B data with valid_in_upstream = 1
//   4. De-assert valid_in_upstream

class mm_driver #(
    parameter int N           = 4,
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32
);

    // Virtual interface handle
    virtual mm_if #(N, DATA_WIDTH, ACCUM_WIDTH) vif;

    // Mailbox from generator
    mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) gen2drv;

    // ── Constructor ─────────────────────────────────────────────
    function new(
        virtual mm_if #(N, DATA_WIDTH, ACCUM_WIDTH)           ifc,
        mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) g2d
    );
        vif     = ifc;
        gen2drv = g2d;
    endfunction

    // Helper: pack A column into flat bus
    function automatic logic [N*DATA_WIDTH-1:0] pack_col_a(
        input logic [DATA_WIDTH-1:0] mat [N][N],
        input int                    col_idx
    );
        logic [N*DATA_WIDTH-1:0] bus;
        for (int r = 0; r < N; r++)
            bus[r*DATA_WIDTH +: DATA_WIDTH] = mat[r][col_idx];
        return bus;
    endfunction

    // Helper: pack B row into flat bus 
    function automatic logic [N*DATA_WIDTH-1:0] pack_row_b(
        input logic [DATA_WIDTH-1:0] mat [N][N],
        input int                    row_idx
    );
        logic [N*DATA_WIDTH-1:0] bus;
        for (int c = 0; c < N; c++)
            bus[c*DATA_WIDTH +: DATA_WIDTH] = mat[row_idx][c];
        return bus;
    endfunction

    // Run task
    task run();
        mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH) txn;

        forever begin
            gen2drv.get(txn);

            $display("[DRIVER]    burst_id=%0d | Driving transaction to DUT", txn.burst_id);

            // Wait for previous transaction to completely finish (DUT returns to IDLE)
            if (txn.burst_id > 1) begin
                wait (vif.result_valid == 1'b1);
                wait (vif.result_valid == 1'b0);
            end

            // Condition Coverage: valid_in_upstream=1 while state != LOAD
            if (txn.burst_id == 8) begin
                @(posedge vif.clk); #1;
                vif.valid_in_upstream = 1'b1;
                $display("[DRIVER]    burst_id=%0d | Injecting valid_in=1 during IDLE for condition coverage", txn.burst_id);
                @(posedge vif.clk); #1;
                vif.valid_in_upstream = 1'b0;
            end

            // Assert start pulse
            @(posedge vif.clk); #1;
            vif.start = 1'b1;
            $display("[DRIVER]    burst_id=%0d | start asserted", txn.burst_id);

            @(posedge vif.clk); #1;
            vif.start = 1'b0;

            // Wait for controller ready
            wait (vif.ready == 1'b1);
            $display("[DRIVER]    burst_id=%0d | DUT ready asserted — beginning data drive", txn.burst_id);

            // Drive N cycles of A/B data
            for (int k = 0; k < N; k++) begin
                // Inject a stall to hit coverage: valid_in_upstream=0 during LOAD state
                if (txn.burst_id == 7 && k == 3) begin
                    @(posedge vif.clk); #1;
                    vif.valid_in_upstream = 1'b0;
                    $display("[DRIVER]    burst_id=%0d | Injecting 1-cycle pipeline stall for coverage", txn.burst_id);
                end

                @(posedge vif.clk); #1;
                vif.a_in              = pack_col_a(txn.A, k);
                vif.b_in              = pack_row_b(txn.B, k);
                vif.valid_in_upstream = 1'b1;

                $display("[DRIVER]    burst_id=%0d | Cycle%0d — a_in=0x%0h  b_in=0x%0h  valid_in=1",
                         txn.burst_id, k, vif.a_in, vif.b_in);
            end

            // De-assert valid
            @(posedge vif.clk); #1;
            vif.valid_in_upstream = 1'b0;
            vif.a_in              = '0;
            vif.b_in              = '0;

            $display("[DRIVER]    burst_id=%0d | valid_in_upstream de-asserted — transaction driven.",
                     txn.burst_id);
        end
    endtask

endclass
