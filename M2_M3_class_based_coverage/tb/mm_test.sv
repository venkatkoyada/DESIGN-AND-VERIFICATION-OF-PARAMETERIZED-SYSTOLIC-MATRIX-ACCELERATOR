class mm_test #(parameter int N = 4,
                parameter int DATA_WIDTH = 8,
                parameter int ACCUM_WIDTH = 32);

    virtual mm_if #(N, DATA_WIDTH, ACCUM_WIDTH) vif;
    int num_tests;

    function new(virtual mm_if #(N, DATA_WIDTH, ACCUM_WIDTH) vif,
                 int num_tests);
        this.vif = vif;
        this.num_tests = num_tests;
    endfunction

    task reset_dut();
        vif.rst_n             = 1'b0;
        vif.start             = 1'b0;
        vif.a_in              = '0;
        vif.b_in              = '0;
        vif.valid_in_upstream = 1'b0;

        $display("[TB_TOP]    Asserting reset for 5 cycles");
        repeat (5) @(posedge vif.clk);

        vif.rst_n = 1'b1;
        repeat (2) @(posedge vif.clk);

        $display("[TB_TOP]    Reset released — launching environment");
    endtask
task manual_fsm_coverage();
    $display("[TB_TOP]    Injecting manual FSM sequences for coverage...");

    // Reset during LOAD
    vif.start <= 1'b1;
    @(posedge vif.clk);
    vif.start <= 1'b0;
    wait(vif.ready);
    vif.valid_in_upstream <= 1'b1;
    vif.a_in <= '0;
    vif.b_in <= '0;
    @(posedge vif.clk);
    vif.rst_n <= 1'b0;
    repeat(2) @(posedge vif.clk);
    vif.rst_n <= 1'b1;
    repeat(2) @(posedge vif.clk);

    // Reset during DRAIN
    vif.start <= 1'b1;
    @(posedge vif.clk);
    vif.start <= 1'b0;
    wait(vif.ready);

    repeat(N) begin
        vif.valid_in_upstream <= 1'b1;
        vif.a_in <= '0;
        vif.b_in <= '0;
        @(posedge vif.clk);
    end

    vif.valid_in_upstream <= 1'b0;
    repeat(2) @(posedge vif.clk);
    vif.rst_n <= 1'b0;
    repeat(2) @(posedge vif.clk);
    vif.rst_n <= 1'b1;
    repeat(2) @(posedge vif.clk);

    // Normal full transaction to hit DONE to IDLE
    vif.start <= 1'b1;
    @(posedge vif.clk);
    vif.start <= 1'b0;
    wait(vif.ready);

    repeat(N) begin
        vif.valid_in_upstream <= 1'b1;
        vif.a_in <= '0;
        vif.b_in <= '0;
        @(posedge vif.clk);
    end

    vif.valid_in_upstream <= 1'b0;
    wait(vif.result_valid);
    repeat(3) @(posedge vif.clk);
endtask
    task run();
        mm_env #(N, DATA_WIDTH, ACCUM_WIDTH) env;

        reset_dut();

        env = new(vif, num_tests);
        env.run();
        manual_fsm_coverage();

        $display("[TB_TOP]    Simulation complete.");
    endtask

endclass
