module input_skew #(
        parameter N          = 4,
        parameter DATA_WIDTH = 8
)(
        input  logic                     clk, rst_n,
        input  logic [N*DATA_WIDTH-1:0]  a_in,
        input  logic [N*DATA_WIDTH-1:0]  b_in,
        input  logic                     valid_in,
        output logic [N*DATA_WIDTH-1:0]  a_skewed,
        output logic [N*DATA_WIDTH-1:0]  b_skewed,
        output logic                     valid_out
);

// 2D shift register arrays — [lane][pipeline stage]
logic [DATA_WIDTH-1:0] a_delay [N][N];
logic [DATA_WIDTH-1:0] b_delay [N][N];

// valid pipeline — needs N-1 stages of delay
logic [N-1:0] valid_delay;

always_ff @(posedge clk) begin
        if (!rst_n) begin
                // clear all delay registers on reset
                for (int i = 0; i < N; i++) begin
                        for (int s = 0; s < N; s++) begin
                                a_delay[i][s] <= '0;
                                b_delay[i][s] <= '0;
                        end
                end
                valid_delay <= '0;

        end else begin
                // stage 0 — capture raw inputs from packed bus
                for (int i = 0; i < N; i++) begin
                        a_delay[i][0] <= a_in[i*DATA_WIDTH +: DATA_WIDTH];
                        b_delay[i][0] <= b_in[i*DATA_WIDTH +: DATA_WIDTH];
                end

                valid_delay[0] <= valid_in;

                // stages 1 to N-1 — shift each stage forward
                for (int s = 1; s < N; s++) begin
                        for (int i = 0; i < N; i++) begin
                                a_delay[i][s] <= a_delay[i][s-1];
                                b_delay[i][s] <= b_delay[i][s-1];
                        end
                        valid_delay[s] <= valid_delay[s-1];
                end
        end
end

// Output assignments — row/col i taps stage i of its delay chain
genvar i;
generate
        for (i = 0; i < N; i++) begin : skew_out
                assign a_skewed[i*DATA_WIDTH +: DATA_WIDTH] = a_delay[i][i];
                assign b_skewed[i*DATA_WIDTH +: DATA_WIDTH] = b_delay[i][i];
        end
endgenerate

// valid_out comes from the deepest stage — last lane has N-1 cycles of delay
assign valid_out = valid_delay[0];

endmodule
