// mm_scoreboard.sv  —  UVM Scoreboard for MM Accelerator
//
// Follows ECE-593 UVM pattern:
//   - extends uvm_scoreboard
//   - `uvm_component_utils (component type, two constructor args)
//   - build_phase  : creates uvm_analysis_imp using new() (NOT factory)
//   - write()      : TLM callback — pushes received transaction to queue
//   - run_phase    : waits for items in queue, pops, calls compare()
//   - compare()    : element-by-element C vs got_C check with `uvm_error / `uvm_info
//   - report_phase : final pass/fail summary via `uvm_info (UVM_LOGGING)
//
// TLM flow:
//   monitor → monitor_port.write(item)
//     → scoreboard_port (uvm_analysis_imp) triggers write()
//       → transactions[$] queue
//         → run_phase pops and calls compare()
//
// The scoreboard receives a COMPLETE seq_item from the monitor:
//   item.C[N][N]     = expected result  (computed by monitor via compute_expected())
//   item.got_C[N][N] = actual DUT result (captured by monitor from result bus)
// So compare() only needs to check C == got_C element-by-element.

class mm_scoreboard extends uvm_scoreboard;

    // ── UVM Factory Registration (component type → two constructor args) ──
    `uvm_component_utils(mm_scoreboard)

    // ── TLM Analysis Imp Port ─────────────────────────────────────────────
    // "Create the handle for the analysis port called scoreboard_port here"
    // uvm_analysis_imp: TWO type params — item type AND implementing class
    // Connected from: agnt.mon.monitor_port → scoreboard_port (in mm_env)
    uvm_analysis_imp #(mm_seq_item, mm_scoreboard) scoreboard_port;

    // ── Transaction Queue ─────────────────────────────────────────────────
    // write() pushes items here; run_phase pops and compares
    mm_seq_item transactions[$];

    // ── Pass/Fail Counters ────────────────────────────────────────────────
    int pass_cnt;     // element-level matches
    int fail_cnt;     // element-level mismatches
    int txn_pass;     // transaction-level pass count
    int txn_fail;     // transaction-level fail count

    // ── Fixed Parameters matching DUT ─────────────────────────────────────
    localparam int N           = 4;
    localparam int ACCUM_WIDTH = 32;

    // ── Standard UVM Constructor ──────────────────────────────────────────
    function new(string name = "mm_scoreboard", uvm_component parent);
        super.new(name, parent);
        `uvm_info("SCB_CLASS", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    // ── Build Phase ───────────────────────────────────────────────────────
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("SCB_CLASS", "Build Phase!", UVM_HIGH)

        // Create analysis port for scoreboard using new() constructor
        // Why not use UVM factory? uvm_analysis_imp is a TLM port,
        // its constructor takes (name, parent) — new() is correct here.
        scoreboard_port = new("scoreboard_port", this);
    endfunction : build_phase

    // ── Connect Phase ─────────────────────────────────────────────────────
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("SCB_CLASS", "Connect Phase!", UVM_HIGH)
    endfunction : connect_phase

    // ── write() — TLM Analysis Imp callback ──────────────────────────────
    // Called automatically by monitor_port.write(item) via TLM mechanism.
    // Must be a function (not task) — TLM analysis imp requires function.
    function void write(mm_seq_item item);
        `uvm_info("SCB_CLASS",
            $sformatf("write() called — queuing transaction (corner_mode=%0d)",
                       item.corner_mode),
            UVM_HIGH)
        transactions.push_back(item);
    endfunction : write

    // ── Run Phase ─────────────────────────────────────────────────────────
    task run_phase(uvm_phase phase);
        mm_seq_item curr_trans;
        `uvm_info("SCB_CLASS", "Run Phase!", UVM_HIGH)

        forever begin
            // Wait until at least one transaction is in the queue
            wait(transactions.size() != 0);

            // Pop oldest transaction (FIFO order)
            curr_trans = transactions.pop_front();

            `uvm_info("SCB_CLASS",
                $sformatf("Checking transaction (corner_mode=%0d) — queue depth after pop: %0d",
                           curr_trans.corner_mode, transactions.size()),
                UVM_MEDIUM)

            // Compare expected C vs actual got_C
            compare(curr_trans);
        end
    endtask : run_phase

    // ── compare: element-by-element C[N][N] vs got_C[N][N] ───────────────
    task compare(mm_seq_item txn);
        bit txn_ok;
        txn_ok = 1'b1;

        `uvm_info("SCB_CLASS",
            $sformatf("--- Comparing transaction (corner_mode=%0d) ---",
                       txn.corner_mode),
            UVM_MEDIUM)

        for (int r = 0; r < N; r++) begin
            for (int c = 0; c < N; c++) begin

                if (txn.C[r][c] === txn.got_C[r][c]) begin
                    // ── MATCH: use `uvm_info (UVM_LOGGING for pass) ───────
                    `uvm_info("COMPARE",
                        $sformatf("C[%0d][%0d]  MATCH      exp=%8d   got=%8d",
                                   r, c, txn.C[r][c], txn.got_C[r][c]),
                        UVM_HIGH)
                    pass_cnt++;

                end else begin
                    // ── MISMATCH: use `uvm_error (UVM_LOGGING for fail) ───
                    `uvm_error("COMPARE",
                        $sformatf("C[%0d][%0d]  MISMATCH   exp=%8d   got=%8d   <<< ERROR",
                                   r, c, txn.C[r][c], txn.got_C[r][c]))
                    fail_cnt++;
                    txn_ok = 1'b0;
                end

            end
        end

        // Transaction-level verdict
        if (txn_ok) begin
            `uvm_info("SCB_CLASS",
                $sformatf("Transaction PASSED   (corner_mode=%0d)   [pass_cnt=%0d]",
                           txn.corner_mode, pass_cnt),
                UVM_LOW)
            txn_pass++;
        end else begin
            `uvm_error("SCB_CLASS",
                $sformatf("Transaction FAILED   (corner_mode=%0d)   [fail_cnt=%0d]",
                           txn.corner_mode, fail_cnt))
            txn_fail++;
        end

    endtask : compare

    // ── Report Phase — final summary via UVM_LOGGING ──────────────────────
    // report_phase is the correct UVM phase for end-of-test reporting.
    // Uses `uvm_info with UVM_NONE verbosity so it always prints.
    function void report_phase(uvm_phase phase);
        `uvm_info("SCB_CLASS",
            "\n======================================================",
            UVM_NONE)
        `uvm_info("SCB_CLASS", "  SCOREBOARD FINAL REPORT", UVM_NONE)
        `uvm_info("SCB_CLASS",
            $sformatf("  Transactions : PASS=%0d   FAIL=%0d",
                       txn_pass, txn_fail),
            UVM_NONE)
        `uvm_info("SCB_CLASS",
            $sformatf("  Elements     : PASS=%0d   FAIL=%0d",
                       pass_cnt, fail_cnt),
            UVM_NONE)

        if (transactions.size() > 0)
            `uvm_warning("SCB_CLASS",
                $sformatf("  %0d transaction(s) remain unprocessed in queue!",
                           transactions.size()))

        if (fail_cnt == 0) begin
            `uvm_info("SCB_CLASS",
                "  OVERALL: *** ALL TESTS PASSED ***",
                UVM_NONE)
        end else begin
            `uvm_error("SCB_CLASS",
                $sformatf("  OVERALL: *** %0d ELEMENT FAILURE(S) DETECTED ***",
                           fail_cnt))
        end

        `uvm_info("SCB_CLASS",
            "======================================================\n",
            UVM_NONE)
    endfunction : report_phase

endclass : mm_scoreboard
