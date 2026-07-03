// mm_scoreboard.sv  —  Scoreboard Class
//
// Receives expected transactions from the generator (gen2scb)
// and captured transactions from the output monitor (mon2scb).
//
// Compares C (expected) vs got_C (actual) element-by-element.
// Reports MATCH / MISMATCH for every element and per transaction.
//
// Maintains pass/fail counters and prints final report.

class mm_scoreboard #(
    parameter int N           = 4,
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32
);

    // Mailboxes 
    mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) gen2scb;   // expected
    mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) mon2scb;   // actual

    // Counters 
    int pass_cnt;
    int fail_cnt;
    int txn_pass;
    int txn_fail;

    // Constructor 
    function new(
        mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) g2s,
        mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) m2s
    );
        gen2scb  = g2s;
        mon2scb  = m2s;
        pass_cnt = 0;
        fail_cnt = 0;
        txn_pass = 0;
        txn_fail = 0;
    endfunction

    // Run task 
    task run();
        mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH) exp_txn, got_txn;
        bit txn_ok;

        forever begin
            gen2scb.get(exp_txn);
            mon2scb.get(got_txn);

            $display("\n[SCB]       burst_id=%0d | Checking transaction", exp_txn.burst_id);

            txn_ok = 1'b1;

            for (int r = 0; r < N; r++) begin
                for (int c = 0; c < N; c++) begin
                    if (exp_txn.C[r][c] === got_txn.got_C[r][c]) begin
                        $display("[SCB]       burst_id=%0d | C[%0d][%0d] MATCH      exp=%0d  got=%0d",
                                 exp_txn.burst_id, r, c, exp_txn.C[r][c], got_txn.got_C[r][c]);
                        pass_cnt++;
                    end else begin
                        $display("[SCB]       burst_id=%0d | C[%0d][%0d] MISMATCH   exp=%0d  got=%0d  <<<<< ERROR",
                                 exp_txn.burst_id, r, c, exp_txn.C[r][c], got_txn.got_C[r][c]);
                        fail_cnt++;
                        txn_ok = 1'b0;
                    end
                end
            end

            if (txn_ok) begin
                $display("[SCB]       burst_id=%0d | Transaction PASSED", exp_txn.burst_id);
                txn_pass++;
            end else begin
                $display("[SCB]       burst_id=%0d | Transaction FAILED", exp_txn.burst_id);
                txn_fail++;
            end
        end
    endtask

    // Final report 
    function void report();
        $display("\n======================================================");
        $display("  SCOREBOARD FINAL REPORT");
        $display("  Transactions:  PASS=%0d  FAIL=%0d", txn_pass, txn_fail);
        $display("  Elements:      PASS=%0d  FAIL=%0d", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("  OVERALL: *** ALL TESTS PASSED ***");
        else
            $display("  OVERALL: *** %0d FAILURES DETECTED ***", fail_cnt);
        $display("======================================================\n");
    endfunction

endclass
