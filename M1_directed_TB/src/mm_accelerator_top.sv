module mm_accelerator_top #(
        parameter N           = 4,
        parameter DATA_WIDTH  = 8,
        parameter ACCUM_WIDTH = 32
)(
        input  logic                       clk, rst_n,
        input  logic                       start,
        input  logic [N*DATA_WIDTH-1:0]    a_in,
        input  logic [N*DATA_WIDTH-1:0]    b_in,
        input  logic                       valid_in_upstream,
        output logic                       ready,
        output logic                       result_valid,
        output logic [N*N*ACCUM_WIDTH-1:0] result
);

// internal wires between modules
wire                       ctrl_valid_in;   // controller → skew + systolic array
wire                       skew_valid_out;  // skew → systolic array
wire [N*DATA_WIDTH-1:0]    a_skewed;        // skew → systolic array
wire [N*DATA_WIDTH-1:0]    b_skewed;        // skew → systolic array

// clear wire added
wire ctrl_clear;


// Controller
// drives ready, valid_in, result_valid
// matrix data bypasses it entirely (Option A)

controller #(
        .N (N)
) u_controller (
        .clk              (clk),
        .rst_n            (rst_n),
        .start            (start),
        .valid_in_upstream(valid_in_upstream),
        .ready            (ready),
        .valid_in         (ctrl_valid_in),
        .result_valid     (result_valid),
	.clear (ctrl_clear)
);


// Input Skew
// staggers a_in and b_in lanes before feeding the systolic array

input_skew #(
        .N          (N),
        .DATA_WIDTH (DATA_WIDTH)
) u_input_skew (
        .clk      (clk),
        .rst_n    (rst_n),
        .a_in     (a_in),
        .b_in     (b_in),
        .valid_in (ctrl_valid_in),
        .a_skewed (a_skewed),
        .b_skewed (b_skewed),
        .valid_out(skew_valid_out)
);


// Systolic Array
// NxN PE grid — computes matrix multiply

systolic_array #(
        .N          (N),
        .DATA_WIDTH (DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
) u_systolic_array (
        .clk      (clk),
        .rst_n    (rst_n),
        .a_row    (a_skewed),
        .b_col    (b_skewed),
        .valid_in (skew_valid_out),
        .result   (result),
        .valid_out(/* not used at top level — result_valid from controller used instead */),
	.clear (ctrl_clear)
);

endmodule
