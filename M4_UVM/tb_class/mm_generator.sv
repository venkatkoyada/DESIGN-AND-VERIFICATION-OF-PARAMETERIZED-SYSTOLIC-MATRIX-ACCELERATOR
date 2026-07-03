// mm_generator.sv  —  Stimulus Generator Class
//
// Creates mm_transaction objects, randomizes them, and sends
// them to the driver via a mailbox.
//
// Parameters:
//   NUM_TESTS : number of transactions to generate


class mm_generator #(
    parameter int N           = 4,
    parameter int DATA_WIDTH  = 8,
    parameter int ACCUM_WIDTH = 32
);

    // Mailboxes
    mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) gen2drv;   // to driver
    mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) gen2scb;   // to scoreboard

    // Config
    int num_tests;

    // Constructor
    function new(
        mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) g2d,
        mailbox #(mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH)) g2s,
        int                                                      n_tests = 20
    );
        gen2drv   = g2d;
        gen2scb   = g2s;
        num_tests = n_tests;
    endfunction

    // Run task
    task run();
        mm_transaction #(N, DATA_WIDTH, ACCUM_WIDTH) txn;

        for (int t = 0; t < num_tests; t++) begin
            txn          = new();
            txn.burst_id = t + 1;

            void'(txn.randomize());

            // Deterministically override the first 6 tests to guarantee 100% coverage bins
            if (t == 0) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 10;   // low
                foreach(txn.B[r,c]) txn.B[r][c] = 10;   // low (C = 400 -> sm)
            end else if (t == 1) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 100;  // mid_low
                foreach(txn.B[r,c]) txn.B[r][c] = 100;  // mid_low (C = 40000 -> lg)
            end else if (t == 2) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 150;  // mid_hi
                foreach(txn.B[r,c]) txn.B[r][c] = 150;  // mid_hi (C = 90000 % 65536 = 24464 -> med)
            end else if (t == 3) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 200;  // high
                foreach(txn.B[r,c]) txn.B[r][c] = 200;  // high (C = 160000 % 65536 = 28928 -> med)
            end else if (t == 4) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 255;  // max_val
                foreach(txn.B[r,c]) txn.B[r][c] = 255;  // max_val (C = 260100 % 65536 = 63492 -> lg)
            end else if (t == 5) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 0;    // zero
                foreach(txn.B[r,c]) txn.B[r][c] = 0;    // zero (C = 0 -> zero)
            end

            // Recompute expected results if we overrode values
            if (t <= 5) txn.compute_expected();

            $display("\n[GENERATOR] burst_id=%0d | Generated transaction (corner_mode=%0d)",
                     txn.burst_id, txn.corner_mode);
            txn.print_inputs();
            txn.print_expected();

            // Forward to driver and scoreboard
            gen2drv.put(txn);
            gen2scb.put(txn);
        end

        $display("[GENERATOR] All %0d transactions generated.", num_tests);
    endtask

endclass
