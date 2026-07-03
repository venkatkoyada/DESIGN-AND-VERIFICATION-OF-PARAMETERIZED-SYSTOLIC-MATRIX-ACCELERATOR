// mm_coverage.sv  —  Coverage Class (stub)
// VCS LIMITATION: covergroup handles cannot be declared as
// class member variables. All actual covergroup instances
// live at module level in tb_class_mm_accelerator.sv.
// This class is kept so mm_env compiles unchanged.

class mm_coverage;

    virtual mm_if #(4, 8, 32) vif;

    function new(virtual mm_if #(4, 8, 32) ifc);
        vif = ifc;
    endfunction

    // Called by generator — no-op here; module CGs sample automatically
    function void sample_txn(mm_transaction #(4, 8, 32) txn);
    endfunction

    // Called by output monitor — no-op here
    function void sample_result_txn(mm_transaction #(4, 8, 32) txn);
    endfunction

    // Keep-alive task required by mm_env fork
    task run();
        forever @(posedge vif.clk);
    endtask

    function void report();
        $display("\n[COV]  Functional coverage collected by module-level");
        $display("[COV]  covergroups in tb_class_mm_accelerator.sv.");
        $display("[COV]  Run: make cov  to see the full code+func report.\n");
    endfunction

endclass
