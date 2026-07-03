module tb_mm_accelerator;


// Parameters

localparam N           = 4;
localparam DATA_WIDTH  = 8;
localparam ACCUM_WIDTH = 32;
localparam CLK_PERIOD  = 10; // 100MHz


// DUT signals

logic                       clk;
logic                       rst_n;
logic                       start;
logic [N*DATA_WIDTH-1:0]    a_in;
logic [N*DATA_WIDTH-1:0]    b_in;
logic                       valid_in_upstream;
logic                       ready;
logic                       result_valid;
logic [N*N*ACCUM_WIDTH-1:0] result;


// DUT instantiation

mm_accelerator_top #(
        .N          (N),
        .DATA_WIDTH (DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
) u_dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .start            (start),
        .a_in             (a_in),
        .b_in             (b_in),
        .valid_in_upstream(valid_in_upstream),
        .ready            (ready),
        .result_valid     (result_valid),
        .result           (result)
);


// Clock generation

initial clk = 0;
always #(CLK_PERIOD/2) clk = ~clk;


// Helper \u2014 pack a flat 2D array into a bus
// matrix[row] maps to lane [row*DATA_WIDTH +: DATA_WIDTH]

function automatic logic [N*DATA_WIDTH-1:0] pack_row(
        input logic [DATA_WIDTH-1:0] mat [N][N],
        input int                    col
);
        logic [N*DATA_WIDTH-1:0] bus;
        for (int i = 0; i < N; i++)
                bus[i*DATA_WIDTH +: DATA_WIDTH] = mat[i][col];
        return bus;
endfunction

function automatic logic [N*DATA_WIDTH-1:0] pack_col(
        input logic [DATA_WIDTH-1:0] mat [N][N],
        input int                    row
);
        logic [N*DATA_WIDTH-1:0] bus;
        for (int j = 0; j < N; j++)
                bus[j*DATA_WIDTH +: DATA_WIDTH] = mat[row][j];
        return bus;
endfunction


// Helper \u2014 read result bus into 2D array

function automatic void unpack_result(
        input  logic [N*N*ACCUM_WIDTH-1:0] res_bus,
        output logic [ACCUM_WIDTH-1:0]     res_mat [N][N]
);
        for (int i = 0; i < N; i++)
                for (int j = 0; j < N; j++)
                        res_mat[i][j] = res_bus[(i*N+j)*ACCUM_WIDTH +: ACCUM_WIDTH];
endfunction


// Helper \u2014 software reference model

function automatic void ref_model(
        input  logic [DATA_WIDTH-1:0]  A [N][N],
        input  logic [DATA_WIDTH-1:0]  B [N][N],
        output logic [ACCUM_WIDTH-1:0] C [N][N]
);
        for (int i = 0; i < N; i++)
                for (int j = 0; j < N; j++) begin
                        C[i][j] = '0;
                        for (int k = 0; k < N; k++)
                                C[i][j] += ACCUM_WIDTH'(A[i][k]) * ACCUM_WIDTH'(B[k][j]);
                end
endfunction


// Helper \u2014 run one matrix multiply and check result

task automatic run_test(
        input string                  test_name,
        input logic [DATA_WIDTH-1:0]  A [N][N],
        input logic [DATA_WIDTH-1:0]  B [N][N]
);
        logic [ACCUM_WIDTH-1:0] expected [N][N];
        logic [ACCUM_WIDTH-1:0] got      [N][N];
        int errors;

        $display("\n========================================");
        $display("TEST: %s", test_name);
        $display("========================================");

        // compute expected result
        ref_model(A, B, expected);

        // reset
        rst_n            <= 0;
        start            <= 0;
        valid_in_upstream <= 0;
        a_in             <= '0;
        b_in             <= '0;
        repeat(4) @(posedge clk);
        rst_n <= 1;
        @(posedge clk);

        // pulse start
        start <= 1;
        @(posedge clk);
        start <= 0;

        // feed N cycles of data \u2014 one column of A and one row of B per cycle
        // a_in carries row-wise data (all rows, one element per row per cycle)
        // b_in carries col-wise data (all cols, one element per col per cycle)
        for (int cycle = 0; cycle < N; cycle++) begin
                @(posedge clk);
                valid_in_upstream <= 1;
                // feed column 'cycle' of A into a_in lanes
                for (int row = 0; row < N; row++)
                        a_in[row*DATA_WIDTH +: DATA_WIDTH] <= A[row][cycle];
                // feed row 'cycle' of B into b_in lanes
                for (int col = 0; col < N; col++)
                        b_in[col*DATA_WIDTH +: DATA_WIDTH] <= B[cycle][col];
        end

        @(posedge clk);
        valid_in_upstream <= 0;
        a_in              <= '0;
        b_in              <= '0;

        // wait for result_valid
        wait (result_valid === 1'b1);
        @(posedge clk);

        // unpack and check
        unpack_result(result, got);
        errors = 0;

        for (int i = 0; i < N; i++) begin
                for (int j = 0; j < N; j++) begin
                        if (got[i][j] !== expected[i][j]) begin
                                $display("  MISMATCH at [%0d][%0d]: got=%0d expected=%0d",
                                         i, j, got[i][j], expected[i][j]);
                                errors++;
                        end
                end
        end

        if (errors == 0)
                $display("  PASS \u2014 all %0d elements match", N*N);
        else
                $display("  FAIL \u2014 %0d mismatches", errors);

endtask


// Test stimulus

logic [DATA_WIDTH-1:0] A [N][N];
logic [DATA_WIDTH-1:0] B [N][N];

initial begin
        //$shm_open("waves.shm");
        //$shm_probe(tb_mm_accelerator, "AS");

        
        // TEST 1 \u2014 All-zeros
        // Expected result: all zeros
        
        foreach (A[i,j]) A[i][j] = '0;
        foreach (B[i,j]) B[i][j] = '0;
        run_test("All-Zeros", A, B);

        
        // TEST 2 \u2014 Identity x Identity
        // Expected result: Identity matrix
        
        foreach (A[i,j]) A[i][j] = (i == j) ? 8'd1 : 8'd0;
        foreach (B[i,j]) B[i][j] = (i == j) ? 8'd1 : 8'd0;
        run_test("Identity x Identity", A, B);

        
        // TEST 3 \u2014 All-ones
        // Expected result: every element = N
        
        foreach (A[i,j]) A[i][j] = 8'd1;
        foreach (B[i,j]) B[i][j] = 8'd1;
        run_test("All-Ones", A, B);

        
        // TEST 4 \u2014 Known random values (hand-verifiable via ref model)
        // A and B filled with small known values, ref_model computes gold
        
        A[0] = '{8'd1,  8'd2,  8'd3,  8'd4 };
        A[1] = '{8'd5,  8'd6,  8'd7,  8'd8 };
        A[2] = '{8'd9,  8'd10, 8'd11, 8'd12};
        A[3] = '{8'd13, 8'd14, 8'd15, 8'd16};

        B[0] = '{8'd2,  8'd0,  8'd1,  8'd0 };
        B[1] = '{8'd0,  8'd2,  8'd0,  8'd1 };
        B[2] = '{8'd1,  8'd0,  8'd2,  8'd0 };
        B[3] = '{8'd0,  8'd1,  8'd0,  8'd2 };
        run_test("Known Random Values", A, B);

        
        $display("\n========================================");
        $display("All tests complete");
        $display("========================================\n");
        $finish;
end


// Timeout watchdog \u2014 kills sim if result_valid never comes

initial begin
        #(CLK_PERIOD * 10000);
        $display("TIMEOUT \u2014 simulation exceeded maximum cycle count");
        $finish;
end

initial begin
    $fsdbDumpfile("novas.fsdb");
    $fsdbDumpvars(0, tb_mm_accelerator);
end
endmodule
