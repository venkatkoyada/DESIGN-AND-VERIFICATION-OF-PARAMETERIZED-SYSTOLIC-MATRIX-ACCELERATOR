// tb_top.sv  —  UVM Top-Level Testbench for MM Accelerator


`timescale 1ns/1ps

`ifndef MATRIX_N
`define MATRIX_N 4
`endif

//  Required: import uvm packages and include macros at the top level 
import uvm_pkg::*;
`include "uvm_macros.svh"

//  Include all UVM TB components — order is important for correct working 
`include "mm_uvm_if.sv" 
`include "mm_seq_item.sv"
`include "mm_sequence.sv"    
`include "mm_sequencer.sv"    
`include "mm_driver.sv"             
`include "mm_monitor.sv"          
`include "mm_agent.sv"        
`include "mm_scoreboard.sv"    
`include "mm_coverage.sv"          
`include "mm_env.sv"           
`include "mm_test.sv"         

module tb_top;

    //  Simulation Parameters 
    localparam int CLK_PERIOD  = 10;       
    localparam int SIM_TIMEOUT = 100_000;  

    //  Clock Generation 
    logic clk;
    initial  clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    //  Interface Instantiation 
    mm_uvm_if intf (.clk(clk));

    //  DUT Instantiation 
    // Connect all interface signals using SystemVerilog connection methods
    mm_accelerator_top #(
        .N          (`MATRIX_N),
        .DATA_WIDTH (8),
        .ACCUM_WIDTH(32)
    ) u_dut (
        .clk               (clk),
        .rst_n             (intf.rst_n),
        .start             (intf.start),
        .a_in              (intf.a_in),
        .b_in              (intf.b_in),
        .valid_in_upstream (intf.valid_in_upstream),
        .ready             (intf.ready),
        .result_valid      (intf.result_valid),
        .result            (intf.result)
    );

    //  Interface Setting — store virtual interface in config_db 
    initial begin
        uvm_config_db #(virtual mm_uvm_if)::set(null, "*", "vif", intf);
    end

    //  Waveform Dump — compile with +define+FSDB to enable Verdi capture 
    `ifdef FSDB
    initial begin
        $fsdbDumpfile("novas_uvm.fsdb");
        $fsdbDumpvars(0, tb_top);
        $display("[TB_TOP] FSDB waveform dump enabled: novas_uvm.fsdb");
    end
    `endif

    //  Start UVM Test 
    initial begin
        run_test("mm_test");
    end


    initial begin
        #SIM_TIMEOUT;
        $display("[TB_TOP] ERROR: Simulation timeout after %0d ns — test may have hung!",
                  SIM_TIMEOUT);
        $finish;
    end
    // VCS coverage on

endmodule : tb_top
