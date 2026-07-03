// ── Matrix size parameter — override on command line: make N=<value> all ──────
// Default = 4 (4×4). Any positive integer works: make N=2 all, make N=8 all.
`ifndef MATRIX_N
`define MATRIX_N 4
`endif

`timescale 1ns/1ps

`include "mm_if.sv"
`include "mm_transaction.sv"
`include "mm_generator.sv"
`include "mm_driver.sv"
`include "mm_monitor.sv"
`include "mm_scoreboard.sv"
`include "mm_coverage.sv"
`include "mm_env.sv"
`include "mm_test.sv"

module tb_class_mm_accelerator;

    localparam int N           = `MATRIX_N;
    localparam int DATA_WIDTH  = 8;
    localparam int ACCUM_WIDTH = 32;
    localparam int CLK_PERIOD  = 10;
    localparam int NUM_TESTS   = 20;

    logic clk;

    initial clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    mm_if #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dut_if (
        .clk(clk)
    );

    mm_accelerator_top #(
        .N(N),
        .DATA_WIDTH(DATA_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) u_dut (
        .clk               (clk),
        .rst_n             (dut_if.rst_n),
        .start             (dut_if.start),
        .a_in              (dut_if.a_in),
        .b_in              (dut_if.b_in),
        .valid_in_upstream (dut_if.valid_in_upstream),
        .ready             (dut_if.ready),
        .result_valid      (dut_if.result_valid),
        .result            (dut_if.result)
    );

    covergroup cg_a_range @(posedge clk iff dut_if.valid_in_upstream);
        option.name = "cg_a_range";
        cp_a : coverpoint dut_if.a_in[7:0] {
            bins zero    = {0};
            bins low     = {[1:63]};
            bins mid_low = {[64:127]};
            bins mid_hi  = {[128:191]};
            bins high    = {[192:254]};
            bins max_val = {255};
        }
    endgroup

    covergroup cg_b_range @(posedge clk iff dut_if.valid_in_upstream);
        option.name = "cg_b_range";
        cp_b : coverpoint dut_if.b_in[7:0] {
            bins zero    = {0};
            bins low     = {[1:63]};
            bins mid_low = {[64:127]};
            bins mid_hi  = {[128:191]};
            bins high    = {[192:254]};
            bins max_val = {255};
        }
    endgroup

    // cg_result samples C[0][0] = result[31:0] (full 32-bit accumulator element).
    // Bins guaranteed for any N≥2 by the deterministic generator overrides:
    //   zero      : t=5  A=B=0              → C[0][0]=0
    //   lo_range  : t=6  identity A, B[0][0]=100 → C[0][0]=100  ∈ [1:255]
    //   mid_range : t=7  A[0][0]=2, B[0][0]=128 → C[0][0]=256  ∈ [256:65535]
    //   hi_range  : t=4  A=B=255            → C[0][0]=N×65025   ≥ 130050 for N≥2
    covergroup cg_result @(posedge clk iff dut_if.result_valid);
        option.name = "cg_result";
        cp_result : coverpoint dut_if.result[31:0] {
            bins zero      = {32'h0000_0000};
            bins lo_range  = {[32'h0000_0001 : 32'h0000_00FF]};
            bins mid_range = {[32'h0000_0100 : 32'h0000_FFFF]};
            bins hi_range  = {[32'h0001_0000 : $]};
        }
    endgroup

    covergroup cg_fsm @(posedge clk);
        option.name = "cg_fsm";

        cp_ready : coverpoint dut_if.ready {
            bins asserted   = {1};
            bins deasserted = {0};
        }

        cp_rv : coverpoint dut_if.result_valid {
            bins inactive = {0};
            bins active   = {1};
        }

        cp_start : coverpoint dut_if.start {
            bins inactive = {0};
            bins active   = {1};
        }

        cx_ready_rv : cross cp_ready, cp_rv {
            ignore_bins impossible =
                binsof(cp_ready.asserted) && binsof(cp_rv.active);
        }
    endgroup

    cg_a_range cg_a_inst   = new();
    cg_b_range cg_b_inst   = new();
    cg_result  cg_res_inst = new();
    cg_fsm     cg_fsm_inst = new();

    task print_cov_report();
        $display("\n==============================================");
        $display("  FUNCTIONAL COVERAGE REPORT");
        $display("  cg_a_range   : %0.1f%%", cg_a_inst.get_coverage());
        $display("  cg_b_range   : %0.1f%%", cg_b_inst.get_coverage());
        $display("  cg_result    : %0.1f%%", cg_res_inst.get_coverage());
        $display("  cg_fsm       : %0.1f%%", cg_fsm_inst.get_coverage());
        $display("==============================================\n");
    endtask

    initial begin
        mm_test #(N, DATA_WIDTH, ACCUM_WIDTH) test;

        `ifdef FSDB
        $fsdbDumpfile("novas_class.fsdb");
        $fsdbDumpvars(0, tb_class_mm_accelerator);
        `endif

        test = new(dut_if, NUM_TESTS);
        test.run();

        print_cov_report();

        $finish;
    end

endmodule
