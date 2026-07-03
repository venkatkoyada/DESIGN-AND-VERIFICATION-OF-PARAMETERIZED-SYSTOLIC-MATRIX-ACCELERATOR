// mm_monitor.sv  —  Input and Output Monitor Classes
//
// Input Monitor (mm_input_monitor):
//   Observes a_in, b_in, valid_in_upstream on every clock edge
//   and prints observed stimulus.
//
// Output Monitor (mm_output_monitor):
//   Waits for result_valid, captures result bus, unpacks it,
//   and pushes captured result into a mailbox to scoreboard.

// Input Monitor
class mm_input_monitor #(
    parameter int N           = 4,
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32
);

    virtual mm_if #(N, DATA_WIDTH, ACCUM_WIDTH) vif;
    int current_burst_id;

    function new(virtual mm_if #(N, DATA_WIDTH, ACCUM_WIDTH) ifc);
        vif              = ifc;
        current_burst_id = 0;
    endfunction

    task run();
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n) begin
                if (vif.start) begin
                    current_burst_id++;
                    $display("[iMon]      burst_id=%0d | start detected — new transaction beginning",
                             current_burst_id);
                end
                if (vif.valid_in_upstream) begin
                    $display("[iMon]      burst_id=%0d | valid_in_upstream=1  a_in=0x%0h  b_in=0x%0h",
                             current_burst_id, vif.a_in, vif.b_in);
                end
                if (vif.result_valid) begin
                    $display("[iMon]      burst_id=%0d | result_valid pulse observed on DUT output",
                             current_burst_id);
                end
            end
        end
    endtask

endclass


// Output Monitor
class mm_output_monitor #(
    parameter int N           = 4,
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32
);

    virtual mm_if #(N, DATA_WIDTH, ACCUM_WIDTH) vif;

    // Mailbox to scoreboard: send captured result
    mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) mon2scb;

    int burst_id_tracker;

    function new(
        virtual mm_if #(N, DATA_WIDTH, ACCUM_WIDTH)           ifc,
        mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) m2s
    );
        vif              = ifc;
        mon2scb          = m2s;
        burst_id_tracker = 0;
    endfunction

    // Helper: unpack flat bus → 2D array
    function automatic void unpack_result(
        input  logic [N*N*ACCUM_WIDTH-1:0] res_bus,
        output logic [ACCUM_WIDTH-1:0]     res_mat [N][N]
    );
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++)
                res_mat[r][c] = res_bus[(r*N+c)*ACCUM_WIDTH +: ACCUM_WIDTH];
    endfunction

    task run();
        mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH) cap_txn;
        logic [ACCUM_WIDTH-1:0] got_mat [N][N];

        forever begin
            // Wait for result_valid
            @(posedge vif.clk iff (vif.rst_n && vif.result_valid));

            burst_id_tracker++;
            unpack_result(vif.result, got_mat);

            cap_txn          = new();
            cap_txn.burst_id = burst_id_tracker;
            cap_txn.got_C    = got_mat;

            $display("[oMon]      burst_id=%0d | result_valid=1 — capturing DUT output",
                     burst_id_tracker);
            for (int r = 0; r < N; r++) begin
                $write("[oMon]        got_C[%0d]=[", r);
                for (int c = 0; c < N; c++) $write("%6d ", got_mat[r][c]);
                $display("]");
            end

            // Send to scoreboard
            mon2scb.put(cap_txn);
        end
    endtask

endclass
