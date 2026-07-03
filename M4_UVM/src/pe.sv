// pe.sv  —  Processing Element (PE) for Systolic Array
//
// Each PE:
//   • latches a_in / b_in to a_out / b_out (horizontal / vertical pass-through)
//   • accumulates a_in * b_in into accum when valid_in is asserted
//   • clears accum synchronously when clear is asserted
//   • DATA_WIDTH  : width of each input operand  (default 8-bit)
//   • ACCUM_WIDTH : width of accumulator         (default 32-bit)

module pe #(
    parameter DATA_WIDTH  = 8,
    parameter ACCUM_WIDTH = 32
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [DATA_WIDTH-1:0]   a_in,
    input  logic [DATA_WIDTH-1:0]   b_in,
    output logic [DATA_WIDTH-1:0]   a_out,
    output logic [DATA_WIDTH-1:0]   b_out,
    output logic [ACCUM_WIDTH-1:0]  accum,
    input  logic                    valid_in,
    output logic                    valid_out,
    input  logic                    clear
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_out     <= '0;
            b_out     <= '0;
            accum     <= '0;
            valid_out <= 1'b0;
        end else begin
            // Pass-through: propagate data one cycle downstream
            a_out     <= a_in;
            b_out     <= b_in;
            valid_out <= valid_in;

            // Accumulate or clear
            if (clear) begin
                accum <= '0;
            end else if (valid_in) begin
                accum <= accum + ACCUM_WIDTH'(a_in) * ACCUM_WIDTH'(b_in);
            end else begin
                accum <= accum;
            end
        end
    end

endmodule
