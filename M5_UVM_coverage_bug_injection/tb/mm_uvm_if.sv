// mm_uvm_if.sv  —  SystemVerilog Interface for UVM MM Accelerator Testbench

interface mm_uvm_if (input logic clk);

    localparam int N           = `MATRIX_N;
    localparam int DATA_WIDTH  = 8;
    localparam int ACCUM_WIDTH = 32;

    // Stimulus signals (driven by UVM driver) 
    logic                        rst_n;             // active-low reset
    logic                        start;             // 1-cycle start pulse
    logic [N*DATA_WIDTH-1:0]     a_in;             // packed A column  [31:0]
    logic [N*DATA_WIDTH-1:0]     b_in;             // packed B row     [31:0]
    logic                        valid_in_upstream; // data-valid qualifier

    // Response signals (sampled by UVM monitor) 
    logic                        ready;             // DUT in LOAD state
    logic                        result_valid;      // result_valid pulse (1 cyc)
    logic [N*N*ACCUM_WIDTH-1:0]  result;           // packed C result  [511:0]

endinterface : mm_uvm_if
