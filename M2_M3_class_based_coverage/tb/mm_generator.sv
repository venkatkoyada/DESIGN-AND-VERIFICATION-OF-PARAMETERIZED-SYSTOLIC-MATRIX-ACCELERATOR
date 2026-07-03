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

            // Deterministically override the first 8 tests to guarantee 100% coverage bins:
            //   t=0: A=B=10    → cg_a/b low bin;    C[0][0]=N×100     (mid_range or hi_range)
            //   t=1: A=B=100   → cg_a/b mid_low;    C[0][0]=N×10000   (mid_range or hi_range)
            //   t=2: A=B=150   → cg_a/b mid_hi;     C[0][0]=N×22500   (mid_range or hi_range)
            //   t=3: A=B=200   → cg_a/b high;       C[0][0]=N×40000   (mid_range or hi_range)
            //   t=4: A=B=255   → cg_a/b max_val;    C[0][0]=N×65025   → hi_range for N≥2
            //   t=5: A=B=0     → cg_a/b zero;       C[0][0]=0         → zero bin
            //   t=6: identity A, B[0][0]=100         C[0][0]=100       → lo_range [1:255]
            //   t=7: A[0][0]=2, B[0][0]=128, rest=0  C[0][0]=256       → mid_range [256:65535]
            if (t == 0) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 10;   // low bin
                foreach(txn.B[r,c]) txn.B[r][c] = 10;
            end else if (t == 1) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 100;  // mid_low bin
                foreach(txn.B[r,c]) txn.B[r][c] = 100;
            end else if (t == 2) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 150;  // mid_hi bin
                foreach(txn.B[r,c]) txn.B[r][c] = 150;
            end else if (t == 3) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 200;  // high bin
                foreach(txn.B[r,c]) txn.B[r][c] = 200;
            end else if (t == 4) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 255;  // max_val bin → cg_result hi_range for N≥2
                foreach(txn.B[r,c]) txn.B[r][c] = 255;
            end else if (t == 5) begin
                foreach(txn.A[r,c]) txn.A[r][c] = 0;    // zero bin → cg_result zero
                foreach(txn.B[r,c]) txn.B[r][c] = 0;
            end else if (t == 6) begin
                // Identity A with B[0][0]=100 → C[0][0]=B[0][0]=100 → cg_result lo_range [1:255]
                foreach(txn.A[r,c]) txn.A[r][c] = (r == c) ? 8'd1 : 8'd0;
                txn.B[0][0] = 8'd100;
            end else if (t == 7) begin
                // A[0][0]=2, B[0][0]=128, all else 0 → C[0][0]=256 → cg_result mid_range [256:65535]
                foreach(txn.A[r,c]) txn.A[r][c] = 8'd0;
                foreach(txn.B[r,c]) txn.B[r][c] = 8'd0;
                txn.A[0][0] = 8'd2;
                txn.B[0][0] = 8'd128;
            end

            // Recompute expected results if we overrode values
            if (t <= 7) txn.compute_expected();

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
