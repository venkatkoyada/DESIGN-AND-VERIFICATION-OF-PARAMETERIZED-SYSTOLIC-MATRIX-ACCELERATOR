// tb_top.sv  —  UVM Top-Level Testbench for MM Accelerator
//
// Follows ECE-593 UVM pattern (test_top):
//   - Imports uvm_pkg and includes uvm_macros.svh at compilation-unit scope
//     (BEFORE any class includes — required for classes to see UVM types)
//   - Includes all UVM TB files in correct dependency order
//   - Instantiates mm_uvm_if (interface) and mm_accelerator_top (DUT)
//   - Stores virtual interface in uvm_config_db (driver + monitor retrieve it)
//   - Launches test via run_test("mm_test")
//   - 10ns clock (100 MHz)
//   - 100µs safety timeout

`timescale 1ns/1ps

// ── Required: import uvm packages and include macros at the top level ─────────
// Must be OUTSIDE the module so all `included class files see these declarations
import uvm_pkg::*;
`include "uvm_macros.svh"

// ── Include all UVM TB components — order is important for correct working ────
// Each file must appear after all its dependencies have been included.
`include "mm_uvm_if.sv"       //  1. Interface   (no class dependencies)
`include "mm_seq_item.sv"     //  2. Sequence Item (extends uvm_sequence_item)
`include "mm_sequence.sv"     //  3. Sequences    (extends uvm_sequence, uses mm_seq_item)
`include "mm_sequencer.sv"    //  4. Sequencer    (extends uvm_sequencer#(mm_seq_item))
`include "mm_driver.sv"       //  5. Driver       (extends uvm_driver#(mm_seq_item))
`include "mm_monitor.sv"      //  6. Monitor      (extends uvm_monitor, uses mm_uvm_if)
`include "mm_agent.sv"        //  7. Agent        (uses mm_sequencer, mm_driver, mm_monitor)
`include "mm_scoreboard.sv"   //  8. Scoreboard   (extends uvm_scoreboard, uses mm_seq_item)
`include "mm_env.sv"          //  9. Environment  (uses mm_agent, mm_scoreboard)
`include "mm_test.sv"         // 10. Test         (uses mm_env and all sequence classes)

// ═════════════════════════════════════════════════════════════════════════════
module tb_top;
// ═════════════════════════════════════════════════════════════════════════════

    // ── Simulation Parameters ─────────────────────────────────────────────
    localparam int CLK_PERIOD  = 10;       // 10 ns → 100 MHz
    localparam int SIM_TIMEOUT = 100_000;  // 100 µs = 10 000 clock cycles

    // ── Clock Generation ──────────────────────────────────────────────────
    logic clk;
    initial  clk = 1'b0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // ── Interface Instantiation ───────────────────────────────────────────
    // Instantiate top module (interface)
    mm_uvm_if intf (.clk(clk));

    // ── DUT Instantiation ─────────────────────────────────────────────────
    // Connect all interface signals using SystemVerilog connection methods
    mm_accelerator_top #(
        .N          (4),
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

    // ── Interface Setting — store virtual interface in config_db ──────────
    // "This is where you will store the virtual interface into the config db"
    // Driver  retrieves with: uvm_config_db#(virtual mm_uvm_if)::get(this,"","vif",vif)
    // Monitor retrieves with: uvm_config_db#(virtual mm_uvm_if)::get(this,"","vif",vif)
    // null + "*" = set globally, visible to all components at any hierarchy
    initial begin
        uvm_config_db #(virtual mm_uvm_if)::set(null, "*", "vif", intf);
    end

    // ── Waveform Dump — compile with +define+FSDB to enable Verdi capture ─
    `ifdef FSDB
    initial begin
        $fsdbDumpfile("novas_uvm.fsdb");
        $fsdbDumpvars(0, tb_top);
        $display("[TB_TOP] FSDB waveform dump enabled: novas_uvm.fsdb");
    end
    `endif

    // ── Start UVM Test ────────────────────────────────────────────────────
    // "Initiate the run_test and what test to run"
    // Override from command line: +UVM_TESTNAME=mm_test
    initial begin
        run_test("mm_test");
    end

    // ── Maximum Simulation Time safety net ────────────────────────────────
    // "Exit simulation for certain cycles if needed"
    // Fires if DUT or TB hangs and UVM never drops its objections.
    initial begin
        #SIM_TIMEOUT;
        $display("[TB_TOP] ERROR: Simulation timeout after %0d ns — test may have hung!",
                  SIM_TIMEOUT);
        $finish;
    end

endmodule : tb_top
