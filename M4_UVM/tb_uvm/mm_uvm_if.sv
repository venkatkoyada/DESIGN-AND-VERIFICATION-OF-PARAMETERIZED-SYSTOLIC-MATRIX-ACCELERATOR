// mm_uvm_if.sv  —  SystemVerilog Interface for UVM MM Accelerator Testbench
//
// Bundles all DUT I/O signals into one interface handle.
// No clocking blocks: UVM driver and monitor use @(posedge clk) directly,
// consistent with the ECE-593 UVM example pattern.
//
// Fixed to match DUT top-level parameters: N=4, DATA_WIDTH=8, ACCUM_WIDTH=32.
//
// Usage in tb_top:
//   mm_uvm_if intf (.clk(clk));
//   uvm_config_db#(virtual mm_uvm_if)::set(null, "*", "vif", intf);

interface mm_uvm_if (input logic clk);

    // Mirrored from DUT mm_accelerator_top parameters
    localparam int N           = 4;
    localparam int DATA_WIDTH  = 8;
    localparam int ACCUM_WIDTH = 32;

    // ── Stimulus signals (driven by UVM driver) ──────────────────────────
    logic                        rst_n;             // active-low reset
    logic                        start;             // 1-cycle start pulse
    logic [N*DATA_WIDTH-1:0]     a_in;             // packed A column  [31:0]
    logic [N*DATA_WIDTH-1:0]     b_in;             // packed B row     [31:0]
    logic                        valid_in_upstream; // data-valid qualifier

    // ── Response signals (sampled by UVM monitor) ────────────────────────
    logic                        ready;             // DUT in LOAD state
    logic                        result_valid;      // result_valid pulse (1 cyc)
    logic [N*N*ACCUM_WIDTH-1:0]  result;           // packed C result  [511:0]

endinterface : mm_uvm_if
