// systolic_array.sv  —  NxN Weight-Stationary Systolic Array
//
// Wires an NxN grid of PEs together.  Data flows:
//   A operands : left-to-right  (a_wire[row][col] → a_wire[row][col+1])
//   B operands : top-to-bottom  (b_wire[row][col] → b_wire[row+1][col])
//
// valid_in propagates diagonally (down-right) through valid_diag
// so each PE sees its valid pulse exactly when its A/B data arrives.
//
// clear is broadcast to all PEs to flush accumulators between runs.

module systolic_array #(
    parameter N          = 4,
    parameter DATA_WIDTH  = 8,
    parameter ACCUM_WIDTH = 32
)(
    input  logic                        clk,
    input  logic                        rst_n,
    input  logic [N*DATA_WIDTH-1:0]     a_row,      // skewed A rows
    input  logic [N*DATA_WIDTH-1:0]     b_col,      // skewed B cols
    input  logic                        valid_in,
    output logic [N*N*ACCUM_WIDTH-1:0]  result,
    output logic                        valid_out,
    input  logic                        clear
);

    // Internal wire declarations
    wire [DATA_WIDTH-1:0]  a_wire [N][N+1];
    wire [DATA_WIDTH-1:0]  b_wire [N+1][N];
    wire [ACCUM_WIDTH-1:0] result_wire [N][N];

    // valid propagates diagonally: valid_diag[i][j] reaches PE(i,j)
    logic valid_diag [N][N];

    // Boundary registers: latch a_row / b_col one cycle
    logic [DATA_WIDTH-1:0] a_boundary [N];
    logic [DATA_WIDTH-1:0] b_boundary [N];

    // Boundary + valid_diag registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < N; i++) begin
                a_boundary[i]   <= '0;
                b_boundary[i]   <= '0;
            end
            for (int i = 0; i < N; i++)
                for (int j = 0; j < N; j++)
                    valid_diag[i][j] <= 1'b0;
        end else begin
            // Latch boundary inputs
            for (int i = 0; i < N; i++) begin
                a_boundary[i] <= a_row[i*DATA_WIDTH +: DATA_WIDTH];
                b_boundary[i] <= b_col[i*DATA_WIDTH +: DATA_WIDTH];
            end

            // Diagonal valid propagation
            valid_diag[0][0] <= valid_in;
            for (int j = 1; j < N; j++)
                valid_diag[0][j] <= valid_diag[0][j-1];
            for (int i = 1; i < N; i++) begin
                valid_diag[i][0] <= valid_diag[i-1][0];
                for (int j = 1; j < N; j++)
                    valid_diag[i][j] <= valid_diag[i-1][j];
            end
        end
    end

    // Boundary wire drives
    genvar i, j;
    generate
        for (i = 0; i < N; i++) begin : boundary_a
            assign a_wire[i][0] = a_boundary[i];
        end
        for (j = 0; j < N; j++) begin : boundary_b
            assign b_wire[0][j] = b_boundary[j];
        end
    endgenerate

    // PE grid instantiation
    generate
        for (i = 0; i < N; i++) begin : row_gen
            for (j = 0; j < N; j++) begin : col_gen
                pe #(
                    .DATA_WIDTH  (DATA_WIDTH),
                    .ACCUM_WIDTH (ACCUM_WIDTH)
                ) u_pe (
                    .clk      (clk),
                    .rst_n    (rst_n),
                    .a_in     (a_wire[i][j]),
                    .a_out    (a_wire[i][j+1]),
                    .b_in     (b_wire[i][j]),
                    .b_out    (b_wire[i+1][j]),
                    .valid_in (valid_diag[i][j]),
                    .valid_out (/* unused — top-level uses controller valid */),
                    .accum    (result_wire[i][j]),
                    .clear    (clear)
                );
            end
        end
    endgenerate

    // Pack result 2-D → flat bus
    generate
        for (i = 0; i < N; i++) begin : pack_row
            for (j = 0; j < N; j++) begin : pack_col
                assign result[(i*N+j)*ACCUM_WIDTH +: ACCUM_WIDTH] = result_wire[i][j];
            end
        end
    endgenerate

    // valid_out driven by bottom-right PE's valid_diag
    assign valid_out = valid_diag[N-1][N-1];

endmodule
