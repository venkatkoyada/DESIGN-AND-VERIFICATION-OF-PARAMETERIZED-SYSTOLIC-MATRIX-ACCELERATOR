// input_skew.sv  —  Input Skewing / Stagger Module
//
// Staggers matrix row (A) and column (B) data so that diagonal
// elements arrive at the systolic array simultaneously.
//
// Lane i (0-indexed) is delayed by i clock cycles.
//   a_skewed[i] = a_in[i]  delayed i cycles
//   b_skewed[i] = b_in[i]  delayed i cycles
//
// valid_out is simply valid_in registered once (pipeline stage 0
// delay), because the skew buffer already absorbs lane latencies
// internally.  Systolic array's own valid_diag fan-out handles
// the per-PE timing.

module input_skew #(
    parameter N          = 4,
    parameter DATA_WIDTH = 8
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [N*DATA_WIDTH-1:0] a_in,
    input  logic [N*DATA_WIDTH-1:0] b_in,
    input  logic                    valid_in,
    output logic [N*DATA_WIDTH-1:0] a_skewed,
    output logic [N*DATA_WIDTH-1:0] b_skewed,
    output logic                    valid_out
);

    // 2-D shift-register buffers: [lane][stage 0..N-1]
    logic [DATA_WIDTH-1:0] a_delay [N][N];
    logic [DATA_WIDTH-1:0] b_delay [N][N];

    // Valid pipeline — only needs 1 register (stage 0)
    logic valid_pipe;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < N; i++)
                for (int s = 0; s < N; s++) begin
                    a_delay[i][s] <= '0;
                    b_delay[i][s] <= '0;
                end
            valid_pipe <= 1'b0;
        end else begin
            // Stage 0: latch raw inputs
            for (int i = 0; i < N; i++) begin
                a_delay[i][0] <= a_in[i*DATA_WIDTH +: DATA_WIDTH];
                b_delay[i][0] <= b_in[i*DATA_WIDTH +: DATA_WIDTH];
            end
            valid_pipe <= valid_in;

            // Stages 1..N-1: shift forward
            for (int s = 1; s < N; s++)
                for (int i = 0; i < N; i++) begin
                    a_delay[i][s] <= a_delay[i][s-1];
                    b_delay[i][s] <= b_delay[i][s-1];
                end
        end
    end

    // Lane i taps stage i of its delay chain
    genvar i;
    generate
        for (i = 0; i < N; i++) begin : skew_out
            assign a_skewed[i*DATA_WIDTH +: DATA_WIDTH] = a_delay[i][i];
            assign b_skewed[i*DATA_WIDTH +: DATA_WIDTH] = b_delay[i][i];
        end
    endgenerate

    // valid_out tracks valid_pipe (one-cycle delay from valid_in)
    assign valid_out = valid_pipe;

endmodule
