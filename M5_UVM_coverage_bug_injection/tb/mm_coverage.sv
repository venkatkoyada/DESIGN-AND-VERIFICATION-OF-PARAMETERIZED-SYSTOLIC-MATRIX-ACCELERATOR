// mm_coverage.sv  —  UVM Coverage Subscriber for MM Accelerator

class mm_coverage extends uvm_subscriber #(mm_seq_item);

    //  UVM Factory Registration (component type → two constructor args) 
    `uvm_component_utils(mm_coverage)

    //  Matrix size — matches DUT; set by make N=<val> 
    localparam int N = `MATRIX_N;

    //  Virtual Interface — for FSM signal-level sampling in run_phase 
    virtual mm_uvm_if vif;

    //  Seq Item Handle 
    mm_seq_item req;

    //  Intermediate Sampling Variables 
    logic [1:0]  curr_mode;      // captures t.corner_mode per transaction
    logic [7:0]  curr_a_val;     // captures t.A[r][c] per element sample
    logic [7:0]  curr_b_val;     // captures t.B[r][c] per element sample
    logic [31:0] curr_c_val;     // captures t.C[r][c] per element sample
    logic        curr_ready;     // captures vif.ready per clock in run_phase
    logic        curr_rv;        // captures vif.result_valid per clock
    logic        curr_start;     // captures vif.start per clock

    //  Per-group coverage real values 
    real cov_mode, cov_a, cov_b, cov_result, cov_fsm;

    //  COVERGROUP 1 — Stimulus corner_mode distribution
   
    covergroup cg_corner_mode;
        option.per_instance = 1;
        option.name         = "cg_corner_mode";
        cp_mode : coverpoint curr_mode {
            bins rand_mode    = {2'b00};
            bins zero_a       = {2'b01};
            bins identity_a   = {2'b10};
            bins all_max      = {2'b11};
        }
    endgroup : cg_corner_mode

    //  COVERGROUP 2 — A matrix element value ranges
    
    covergroup cg_a_vals;
        option.per_instance = 1;
        option.name         = "cg_a_vals";
        cp_a : coverpoint curr_a_val {
            bins zero    = {8'h00};
            bins low     = {[8'h01 : 8'h3F]};
            bins mid_lo  = {[8'h40 : 8'h7F]};
            bins mid_hi  = {[8'h80 : 8'hBF]};
            bins high    = {[8'hC0 : 8'hFE]};
            bins max_val = {8'hFF};
        }
    endgroup : cg_a_vals

    //  COVERGROUP 3 — B matrix element value ranges
    
    covergroup cg_b_vals;
        option.per_instance = 1;
        option.name         = "cg_b_vals";
        cp_b : coverpoint curr_b_val {
            bins zero    = {8'h00};
            bins low     = {[8'h01 : 8'h3F]};
            bins mid_lo  = {[8'h40 : 8'h7F]};
            bins mid_hi  = {[8'h80 : 8'hBF]};
            bins high    = {[8'hC0 : 8'hFE]};
            bins max_val = {8'hFF};
        }
    endgroup : cg_b_vals

    //  COVERGROUP 4 — Output C[r][c] expected value ranges
   
    covergroup cg_result_vals;
        option.per_instance = 1;
        option.name         = "cg_result_vals";
        cp_c : coverpoint curr_c_val {
            bins zero      = {32'h0000_0000};
            bins lo_range  = {[32'h0000_0001 : 32'h0000_00FF]};
            bins mid_range = {[32'h0000_0100 : 32'h0000_FFFF]};
            bins hi_range  = {[32'h0001_0000 : $]};
        }
    endgroup : cg_result_vals

    //  COVERGROUP 5 — FSM protocol signal states + cross coverage
   
    covergroup cg_fsm_signals;
        option.per_instance = 1;
        option.name         = "cg_fsm_signals";

        cp_ready : coverpoint curr_ready {
            bins deasserted = {1'b0};
            bins asserted   = {1'b1};
        }

        cp_rv : coverpoint curr_rv {
            bins inactive = {1'b0};
            bins active   = {1'b1};
        }

        cp_start : coverpoint curr_start {
            bins inactive = {1'b0};
            bins active   = {1'b1};
        }

        cx_ready_rv : cross cp_ready, cp_rv {
            ignore_bins impossible =
                binsof(cp_ready.asserted) && binsof(cp_rv.active);
        }
    endgroup : cg_fsm_signals

    //  Standard UVM Constructor

    function new(string name = "mm_coverage", uvm_component parent);
        super.new(name, parent);
        `uvm_info("COV_CLASS", "Inside Constructor!", UVM_HIGH)

        // Create seq item handle via UVM factory (professor slide 41 pattern)
        req = mm_seq_item::type_id::create("req");

        // Allocate covergroup instances — cg = new() in constructor (slide 41)
        cg_corner_mode = new();
        cg_a_vals      = new();
        cg_b_vals      = new();
        cg_result_vals = new();
        cg_fsm_signals = new();
    endfunction : new

    //  Build Phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("COV_CLASS", "Build Phase!", UVM_HIGH)

        if (!uvm_config_db #(virtual mm_uvm_if)::get(this, "", "vif", vif))
            `uvm_fatal("COV_CLASS",
                "Failed to get virtual mm_uvm_if from config DB. Check tb_top set() call.")
    endfunction : build_phase

    //  Connect Phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("COV_CLASS", "Connect Phase!", UVM_HIGH)
    endfunction : connect_phase

    //  write() — TLM callback triggered by monitor_port.write(item)
    virtual function void write(mm_seq_item t);
        // Update seq item handle (slide 42: req = t)
        req = t;

        // 1. Infer corner_mode from observed A/B matrices
        // The monitor creates a fresh seq_item and never sets corner_mode,
        // so t.corner_mode is uninitialized (2'bx) — no bins would match.
        // Instead, infer the mode from the matrix contents that the monitor
        // DID observe (A and B are filled from the DUT interface signals).
        begin
            bit all_a_zero   = 1;
            bit a_is_identity = 1;
            bit all_ab_max   = 1;
            for (int r = 0; r < N; r++)
                for (int c = 0; c < N; c++) begin
                    if (t.A[r][c] != 8'h00) all_a_zero    = 0;
                    if (t.A[r][c] != ((r==c) ? 8'd1 : 8'd0)) a_is_identity = 0;
                    if (t.A[r][c] != 8'hFF || t.B[r][c] != 8'hFF) all_ab_max = 0;
                end
            if      (all_a_zero)    curr_mode = 2'b01;   // zero_a mode
            else if (a_is_identity) curr_mode = 2'b10;   // identity_a mode
            else if (all_ab_max)    curr_mode = 2'b11;   // all_max mode
            else                    curr_mode = 2'b00;   // rand_mode (default)
        end

        `uvm_info("COV_CLASS",
            $sformatf("write() — inferred corner_mode=%0d", curr_mode),
            UVM_HIGH)

        cg_corner_mode.sample();

        //  2. Sample all N×N A matrix elements
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                curr_a_val = t.A[r][c];
                cg_a_vals.sample();
            end

        //  3. Sample all N×N B matrix elements
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                curr_b_val = t.B[r][c];
                cg_b_vals.sample();
            end

        //  4. Sample all N×N expected output C elements
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                curr_c_val = t.C[r][c];
                cg_result_vals.sample();
            end

        // Running coverage readout (slide 42: cg.get_coverage())
        cov_mode   = cg_corner_mode.get_coverage();
        cov_a      = cg_a_vals.get_coverage();
        cov_b      = cg_b_vals.get_coverage();
        cov_result = cg_result_vals.get_coverage();

        `uvm_info("COV_CLASS",
            $sformatf("Running cov: mode=%.1f%%  A=%.1f%%  B=%.1f%%  result=%.1f%%",
                       cov_mode, cov_a, cov_b, cov_result),
            UVM_MEDIUM)
    endfunction : write

    //  Run Phase — clock-driven FSM signal sampling
    task run_phase(uvm_phase phase);
        `uvm_info("COV_CLASS", "Run Phase — FSM signal sampling active", UVM_HIGH)
        forever @(posedge vif.clk) begin
            curr_ready = vif.ready;
            curr_rv    = vif.result_valid;
            curr_start = vif.start;
            cg_fsm_signals.sample();
        end
    endtask : run_phase

    //  Report Phase — final functional coverage summary
    function void report_phase(uvm_phase phase);
        cov_mode   = cg_corner_mode.get_coverage();
        cov_a      = cg_a_vals.get_coverage();
        cov_b      = cg_b_vals.get_coverage();
        cov_result = cg_result_vals.get_coverage();
        cov_fsm    = cg_fsm_signals.get_coverage();

        `uvm_info("COV_CLASS",
            "\n============================================================",
            UVM_NONE)
        `uvm_info("COV_CLASS", "  FUNCTIONAL COVERAGE REPORT", UVM_NONE)
        `uvm_info("COV_CLASS",
            "------------------------------------------------------------",
            UVM_NONE)
        `uvm_info("COV_CLASS",
            $sformatf("  cg_corner_mode  : %6.2f%%  [4 bins : random/zero_a/identity_a/all_max]",
                       cov_mode),
            UVM_NONE)
        `uvm_info("COV_CLASS",
            $sformatf("  cg_a_vals       : %6.2f%%  [6 bins : zero/low/mid_lo/mid_hi/high/max]",
                       cov_a),
            UVM_NONE)
        `uvm_info("COV_CLASS",
            $sformatf("  cg_b_vals       : %6.2f%%  [6 bins : zero/low/mid_lo/mid_hi/high/max]",
                       cov_b),
            UVM_NONE)
        `uvm_info("COV_CLASS",
            $sformatf("  cg_result_vals  : %6.2f%%  [4 bins : zero/lo_range/mid_range/hi_range]",
                       cov_result),
            UVM_NONE)
        `uvm_info("COV_CLASS",
            $sformatf("  cg_fsm_signals  : %6.2f%%  [ready/rv/start bins + ready×rv cross]",
                       cov_fsm),
            UVM_NONE)
        `uvm_info("COV_CLASS",
            "------------------------------------------------------------",
            UVM_NONE)

        if (cov_mode   == 100.0 && cov_a      == 100.0 &&
            cov_b      == 100.0 && cov_result  == 100.0 &&
            cov_fsm    == 100.0) begin
            `uvm_info("COV_CLASS",
                "  *** FUNCTIONAL COVERAGE : 100%  — ALL BINS HIT ***",
                UVM_NONE)
        end else begin
            `uvm_warning("COV_CLASS",
                "  FUNCTIONAL COVERAGE INCOMPLETE — check bins above")
        end

        `uvm_info("COV_CLASS",
            "  Code coverage (line/branch/cond/fsm/tgl) collected by VCS -cm flags.",
            UVM_NONE)
        `uvm_info("COV_CLASS",
            "  View code + functional report with:  make cov",
            UVM_NONE)
        `uvm_info("COV_CLASS",
            "============================================================\n",
            UVM_NONE)
    endfunction : report_phase

endclass : mm_coverage
