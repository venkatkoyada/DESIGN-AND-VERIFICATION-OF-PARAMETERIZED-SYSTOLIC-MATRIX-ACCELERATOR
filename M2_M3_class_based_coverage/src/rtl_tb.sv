// rtl_tb.sv  —  Simple Directed Testbench for MM Accelerator RTL
//
// Purpose: lightweight sanity check of the RTL for any matrix size N.
//   Runs 5 directed tests without a full verification environment:
//     Test 1 : All-zero A        → C must be all zeros
//     Test 2 : Identity A        → C must equal B
//     Test 3 : All-max A & B     → overflow boundary (N × 255 × 255)
//     Test 4 : All-zero B        → C must be all zeros
//     Test 5 : Random A & B      → compare against reference model
//
// Parameterization: compile with +define+MATRIX_N=<N>  (default 4)
//   make N=2 all  /  make N=4 all  /  make N=8 all  etc.
//
// Protocol: identical to the DUT handshake used by CLASS_TB and UVM_TB
//   start pulse → wait ready → N cycles of a_in/b_in/valid=1 →
//   deassert valid → wait result_valid → capture result bus

`ifndef MATRIX_N
`define MATRIX_N 4
`endif

`timescale 1ns/1ps

module rtl_tb;

    // ── Parameters ────────────────────────────────────────────────────────────
    localparam int N           = `MATRIX_N;
    localparam int DATA_WIDTH  = 8;
    localparam int ACCUM_WIDTH = 32;
    localparam int CLK_PERIOD  = 10;
    localparam int SIM_TIMEOUT = 500_000;  // 500 µs safety net

    // ── DUT Signals ──────────────────────────────────────────────────────────
    logic                       clk;
    logic                       rst_n;
    logic                       start;
    logic [N*DATA_WIDTH-1:0]    a_in;
    logic [N*DATA_WIDTH-1:0]    b_in;
    logic                       valid_in_upstream;
    logic                       ready;
    logic                       result_valid;
    logic [N*N*ACCUM_WIDTH-1:0] result;

    // ── Test Data (module-level so tasks can share them) ─────────────────────
    logic [DATA_WIDTH-1:0]  A         [N][N];
    logic [DATA_WIDTH-1:0]  B         [N][N];
    logic [ACCUM_WIDTH-1:0] expected_C[N][N];
    logic [ACCUM_WIDTH-1:0] got_C     [N][N];

    // ── Pass/Fail Counters ────────────────────────────────────────────────────
    int pass_cnt;
    int fail_cnt;

    // ── Clock Generation ──────────────────────────────────────────────────────
    initial clk = 1'b0;
    always  #(CLK_PERIOD/2) clk = ~clk;

    // ── DUT Instantiation ─────────────────────────────────────────────────────
    mm_accelerator_top #(
        .N          (N),
        .DATA_WIDTH (DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) u_dut (
        .clk               (clk),
        .rst_n             (rst_n),
        .start             (start),
        .a_in              (a_in),
        .b_in              (b_in),
        .valid_in_upstream (valid_in_upstream),
        .ready             (ready),
        .result_valid      (result_valid),
        .result            (result)
    );

    // ── Waveform Dump ─────────────────────────────────────────────────────────
    `ifdef FSDB
    initial begin
        $fsdbDumpfile("novas_rtl.fsdb");
        $fsdbDumpvars(0, rtl_tb);
    end
    `endif

    // ═══════════════════════════════════════════════════════════════════════════
    // HELPER TASKS / FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════

    // Pack column col_idx of mat into flat [N*DW-1:0] a_in bus
    function automatic logic [N*DATA_WIDTH-1:0] pack_col_a(
        input logic [DATA_WIDTH-1:0] mat     [N][N],
        input int                    col_idx
    );
        logic [N*DATA_WIDTH-1:0] bus;
        for (int r = 0; r < N; r++)
            bus[r*DATA_WIDTH +: DATA_WIDTH] = mat[r][col_idx];
        return bus;
    endfunction

    // Pack row row_idx of mat into flat [N*DW-1:0] b_in bus
    function automatic logic [N*DATA_WIDTH-1:0] pack_row_b(
        input logic [DATA_WIDTH-1:0] mat     [N][N],
        input int                    row_idx
    );
        logic [N*DATA_WIDTH-1:0] bus;
        for (int c = 0; c < N; c++)
            bus[c*DATA_WIDTH +: DATA_WIDTH] = mat[row_idx][c];
        return bus;
    endfunction

    // Reference model: compute C = A × B into expected_C
    task automatic compute_expected();
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                expected_C[r][c] = '0;
                for (int k = 0; k < N; k++)
                    expected_C[r][c] +=
                        ACCUM_WIDTH'(A[r][k]) * ACCUM_WIDTH'(B[k][c]);
            end
    endtask

    // Unpack flat result bus → got_C[N][N]
    task automatic unpack_result();
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++)
                got_C[r][c] = result[(r*N+c)*ACCUM_WIDTH +: ACCUM_WIDTH];
    endtask

    // Drive one complete matrix-multiply transaction:
    //   start pulse → wait ready → N data cycles → deassert valid → wait result_valid
    task automatic drive_transaction();
        // Start pulse (1 cycle)
        @(posedge clk); #1;
        start = 1'b1;
        @(posedge clk); #1;
        start = 1'b0;

        // Wait for controller to enter LOAD (ready=1)
        wait (ready == 1'b1);

        // Drive N cycles of packed A columns and B rows
        for (int k = 0; k < N; k++) begin
            @(posedge clk); #1;
            a_in              = pack_col_a(A, k);
            b_in              = pack_row_b(B, k);
            valid_in_upstream = 1'b1;
        end

        // Deassert valid — data phase complete
        @(posedge clk); #1;
        valid_in_upstream = 1'b0;
        a_in = '0;
        b_in = '0;

        // Wait for DUT to pulse result_valid (DONE state)
        wait (result_valid == 1'b1);
        @(posedge clk);  // capture result on the same edge
    endtask

    // Compare expected_C vs got_C, report each element
    task automatic check_and_report(input string test_name);
        bit ok;
        ok = 1'b1;
        $display("\n[CHECK] %-30s", test_name);
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                if (expected_C[r][c] === got_C[r][c]) begin
                    $display("  C[%0d][%0d]  MATCH      exp=%0d  got=%0d",
                             r, c, expected_C[r][c], got_C[r][c]);
                    pass_cnt++;
                end else begin
                    $display("  C[%0d][%0d]  MISMATCH   exp=%0d  got=%0d  <<< ERROR",
                             r, c, expected_C[r][c], got_C[r][c]);
                    fail_cnt++;
                    ok = 1'b0;
                end
            end
        if (ok) $display("[CHECK] %s  PASSED", test_name);
        else    $display("[CHECK] %s  FAILED  <<<", test_name);
    endtask

    // ═══════════════════════════════════════════════════════════════════════════
    // MAIN TEST SEQUENCE
    // ═══════════════════════════════════════════════════════════════════════════
    initial begin
        pass_cnt = 0;
        fail_cnt = 0;

        $display("========================================================");
        $display("  RTL SIMPLE TESTBENCH  (N = %0d x %0d)", N, N);
        $display("  Systolic Array Matrix-Multiply Accelerator  ECE 593");
        $display("========================================================\n");

        // ── Reset ─────────────────────────────────────────────────────────────
        rst_n             = 1'b0;
        start             = 1'b0;
        a_in              = '0;
        b_in              = '0;
        valid_in_upstream = 1'b0;

        repeat(5) @(posedge clk);
        @(posedge clk); #1;
        rst_n = 1'b1;
        repeat(2) @(posedge clk);
        $display("[RTL_TB] Reset released — DUT initialised\n");

        // ── Test 1: All-zero A → C must be all zeros ──────────────────────────
        $display("[RTL_TB] Test 1 : All-zero A  (expect C = 0)");
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                A[r][c] = 8'h00;
                B[r][c] = 8'(r * N + c + 1);  // non-zero B to expose errors
            end
        compute_expected();
        drive_transaction();
        unpack_result();
        check_and_report("Test1 all-zero A");

        // ── Test 2: Identity A → C must equal B ───────────────────────────────
        $display("\n[RTL_TB] Test 2 : Identity A  (expect C = B)");
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                A[r][c] = (r == c) ? 8'd1 : 8'd0;
                B[r][c] = 8'($urandom_range(0, 255));
            end
        compute_expected();
        drive_transaction();
        unpack_result();
        check_and_report("Test2 identity A");

        // ── Test 3: All-max A & B → overflow boundary ─────────────────────────
        $display("\n[RTL_TB] Test 3 : All-max A & B  (N x 255 x 255 = %0d per element)", N*255*255);
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                A[r][c] = 8'hFF;
                B[r][c] = 8'hFF;
            end
        compute_expected();
        drive_transaction();
        unpack_result();
        check_and_report("Test3 all-max");

        // ── Test 4: All-zero B → C must be all zeros ──────────────────────────
        $display("\n[RTL_TB] Test 4 : All-zero B  (expect C = 0)");
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                A[r][c] = 8'($urandom_range(1, 255));
                B[r][c] = 8'h00;
            end
        compute_expected();
        drive_transaction();
        unpack_result();
        check_and_report("Test4 all-zero B");

        // ── Test 5: Random A & B ──────────────────────────────────────────────
        $display("\n[RTL_TB] Test 5 : Random A & B");
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                A[r][c] = 8'($urandom_range(0, 255));
                B[r][c] = 8'($urandom_range(0, 255));
            end
        compute_expected();
        drive_transaction();
        unpack_result();
        check_and_report("Test5 random");

        // ── Final Report ──────────────────────────────────────────────────────
        $display("\n========================================================");
        $display("  RTL TESTBENCH FINAL REPORT  (N = %0d x %0d)", N, N);
        $display("  Elements checked : %0d", pass_cnt + fail_cnt);
        $display("  PASS : %0d   FAIL : %0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("  RESULT : *** ALL RTL TESTS PASSED ***");
        else
            $display("  RESULT : *** %0d ELEMENT FAILURES — CHECK RTL ***", fail_cnt);
        $display("========================================================\n");

        $finish;
    end

    // ── Safety timeout ────────────────────────────────────────────────────────
    // VCS coverage off
    initial begin
        #SIM_TIMEOUT;
        $display("[RTL_TB] ERROR: Simulation timeout after %0d ns — DUT may have hung!", SIM_TIMEOUT);
        $finish;
    end
    // VCS coverage on

endmodule
