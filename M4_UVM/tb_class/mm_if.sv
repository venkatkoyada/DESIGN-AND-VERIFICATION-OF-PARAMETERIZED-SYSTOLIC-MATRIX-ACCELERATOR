// mm_if.sv  —  SystemVerilog Interface for MM Accelerator
//
// Bundles all DUT I/O signals into a single interface.
// Parameters match the DUT top-level parameters.

interface mm_if #(
    parameter int N           = 4,
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32
)(
    input logic clk
);

    // DUT signals   
    logic                        rst_n;
    logic                        start;
    logic [N*DATA_WIDTH-1:0]     a_in;
    logic [N*DATA_WIDTH-1:0]     b_in;
    logic                        valid_in_upstream;
    logic                        ready;
    logic                        result_valid;
    logic [N*N*ACCUM_WIDTH-1:0]  result;

    // Driver clocking block
    clocking driver_cb @(posedge clk);
        default input #1 output #1;
        output rst_n;
        output start;
        output a_in;
        output b_in;
        output valid_in_upstream;
        input  ready;
        input  result_valid;
        input  result;
    endclocking

    // Monitor clocking block
    clocking monitor_cb @(posedge clk);
        default input #1;
        input rst_n;
        input start;
        input a_in;
        input b_in;
        input valid_in_upstream;
        input ready;
        input result_valid;
        input result;
    endclocking

    // Modport definitions
    modport driver_mp  (clocking driver_cb,  input clk);
    modport monitor_mp (clocking monitor_cb, input clk);
    modport dut_mp (
        input  clk,
        input  rst_n,
        input  start,
        input  a_in,
        input  b_in,
        input  valid_in_upstream,
        output ready,
        output result_valid,
        output result
    );

endinterface
