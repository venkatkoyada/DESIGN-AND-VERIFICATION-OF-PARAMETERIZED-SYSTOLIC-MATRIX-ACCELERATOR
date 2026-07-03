// mm_transaction.sv  —  Transaction Class
//
// Represents one full NxN matrix-multiply stimulus + response.
// Fields:
//   A [N][N]    : input matrix A (randomizable)
//   B [N][N]    : input matrix B (randomizable)
//   C [N][N]    : expected result (computed by ref model)
//   got_C [N][N]: actual DUT result
//   burst_id    : transaction sequence number
//
// Constraints:
//   c_data_valid : all values in [0,255]
//   c_corner_zero: 10% chance of all-zero A  (for coverage)
//   c_corner_max : 5%  chance of all-FF A,B  (overflow corner)

class mm_transaction #(
    parameter int N           = 4,
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32
);

    // Fields 
    rand logic [DATA_WIDTH-1:0]  A [N][N];
    rand logic [DATA_WIDTH-1:0]  B [N][N];
    rand logic [1:0]             corner_mode;   // 0=random,1=zero,2=identity,3=max

    logic [ACCUM_WIDTH-1:0] C     [N][N];   // expected (ref model output)
    logic [ACCUM_WIDTH-1:0] got_C [N][N];   // actual DUT output

    int burst_id;

    // Constraints 
    constraint c_corner_dist {
        corner_mode dist { 0 := 70,   // normal random
                           1 := 10,   // all-zero A
                           2 := 10,   // identity A
                           3 := 10 }; // max values
    }

    constraint c_data_range {
        foreach (A[r,c]) A[r][c] inside {[0:255]};
        foreach (B[r,c]) B[r][c] inside {[0:255]};
    }

    // Post-randomize: apply corner overrides 
    function void post_randomize();
        case (corner_mode)
            2'b01: begin  // all-zero A
                foreach (A[r,c]) A[r][c] = '0;
            end
            2'b10: begin  // identity A
                foreach (A[r,c]) A[r][c] = (r == c) ? 8'd1 : 8'd0;
            end
            2'b11: begin  // max values
                foreach (A[r,c]) A[r][c] = {DATA_WIDTH{1'b1}};
                foreach (B[r,c]) B[r][c] = {DATA_WIDTH{1'b1}};
            end
            default: ;  // keep random values
        endcase
        // Compute reference result
        compute_expected();
    endfunction

    // Reference model: C = A * B 
    function void compute_expected();
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                C[r][c] = '0;
                for (int k = 0; k < N; k++)
                    C[r][c] += ACCUM_WIDTH'(A[r][k]) * ACCUM_WIDTH'(B[k][c]);
            end
    endfunction

    // Display helpers 
    function void print_inputs();
        $display("[TRANSACTION] burst_id=%0d | A and B matrices:", burst_id);
        for (int r = 0; r < N; r++) begin
            $write("[TRANSACTION]   A[%0d]=[", r);
            for (int c = 0; c < N; c++) $write("%3d ", A[r][c]);
            $write("] B[%0d]=[", r);
            for (int c = 0; c < N; c++) $write("%3d ", B[r][c]);
            $display("]");
        end
    endfunction

    function void print_expected();
        $display("[TRANSACTION] burst_id=%0d | Expected C:", burst_id);
        for (int r = 0; r < N; r++) begin
            $write("[TRANSACTION]   C[%0d]=[", r);
            for (int c = 0; c < N; c++) $write("%6d ", C[r][c]);
            $display("]");
        end
    endfunction

    function void print_got();
        $display("[TRANSACTION] burst_id=%0d | DUT got_C:", burst_id);
        for (int r = 0; r < N; r++) begin
            $write("[TRANSACTION]   got_C[%0d]=[", r);
            for (int c = 0; c < N; c++) $write("%6d ", got_C[r][c]);
            $display("]");
        end
    endfunction

endclass
