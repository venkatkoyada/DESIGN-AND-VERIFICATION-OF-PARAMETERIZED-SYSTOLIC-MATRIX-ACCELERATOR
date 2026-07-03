// mm_env.sv  —  Verification Environment Class
//
// Instantiates and connects all verification components:
//   Generator → Driver       (gen2drv mailbox)
//   Generator → Scoreboard   (gen2scb mailbox)
//   OutputMonitor → Scoreboard (mon2scb mailbox)
//
// Environment also creates Coverage object and wires virtual if.

class mm_env #(
    parameter int N           = 4,
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32
);

    // Component handles
    mm_generator    #(N, DATA_WIDTH, ACCUM_WIDTH) gen;
    mm_driver       #(N, DATA_WIDTH, ACCUM_WIDTH) drv;
    mm_input_monitor  #(N, DATA_WIDTH, ACCUM_WIDTH) i_mon;
    mm_output_monitor #(N, DATA_WIDTH, ACCUM_WIDTH) o_mon;
    mm_scoreboard   #(N, DATA_WIDTH, ACCUM_WIDTH) scb;
    mm_coverage     cov;

    // Mailboxes
    mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) gen2drv;
    mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) gen2scb;
    mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) mon2scb;

    // Virtual interface
    virtual mm_if #(N, DATA_WIDTH, ACCUM_WIDTH) vif;

    // Number of tests
    int num_tests;

    // Constructor
    function new(
        virtual mm_if #(N, DATA_WIDTH, ACCUM_WIDTH) ifc,
        int                                         n_tests = 20
    );
        vif       = ifc;
        num_tests = n_tests;

        // Create mailboxes (unbounded)
        gen2drv = new();
        gen2scb = new();
        mon2scb = new();

        // Create components
        gen   = new(gen2drv, gen2scb, num_tests);
        drv   = new(vif, gen2drv);
        i_mon = new(vif);
        o_mon = new(vif, mon2scb);
        scb   = new(gen2scb, mon2scb);
        cov   = new(vif);
    endfunction

    // Run: fork all components in parallel
    task run();
        $display("[ENV]       Starting verification environment (%0d tests)", num_tests);

        fork
            gen.run();
            drv.run();
            i_mon.run();
            o_mon.run();
            scb.run();
            cov.run();
        join_none

        // Wait for generator to finish all transactions
        wait (gen2drv.num() == 0 && gen2scb.num() == 0);

        // Wait for scoreboard to process all results
        // (wait for output monitor to have processed num_tests results)
        // We allow generous settling time for pipeline drain
        repeat (num_tests * (4 * N + 20)) @(posedge vif.clk);

        // Final reports
        scb.report();
        cov.report();

        $display("[ENV]       Environment run complete.");
    endtask

endclass
