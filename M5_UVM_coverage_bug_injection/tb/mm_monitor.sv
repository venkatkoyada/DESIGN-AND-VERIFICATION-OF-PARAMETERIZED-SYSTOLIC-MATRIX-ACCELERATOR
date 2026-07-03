// mm_monitor.sv  —  UVM Monitor for MM Accelerator

class mm_monitor extends uvm_monitor;

    // UVM Factory Registration (component type → two constructor args)
    `uvm_component_utils(mm_monitor)

    // Virtual Interface Handle
    // Monitor needs access to virtual interface to interact with DUT
    virtual mm_uvm_if vif;

    // Sequence Item Handle
    // Factory object for the transaction to be observed
    mm_seq_item item;

    // TLM Analysis Port
    // "Create the handle for the analysis port called monitor_port here"
    // Connected to scoreboard's analysis imp in mm_env connect_phase
    uvm_analysis_port #(mm_seq_item) monitor_port;

    // Fixed Parameters matching DUT — N set by make N=<val>
    localparam int N           = `MATRIX_N;
    localparam int DATA_WIDTH  = 8;
    localparam int ACCUM_WIDTH = 32;

    // Standard UVM Constructor
    function new(string name = "mm_monitor", uvm_component parent);
        super.new(name, parent);
        `uvm_info("MONITOR_CLASS", "Inside Constructor!", UVM_HIGH)
    endfunction : new

    //  Build Phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("MONITOR_CLASS", "Build Phase!", UVM_HIGH)

        // Need to create the monitor port using new() constructor
        monitor_port = new("monitor_port", this);

        // Get virtual interface pointer from centralized config_db
        if (!uvm_config_db #(virtual mm_uvm_if)::get(this, "", "vif", vif))
            `uvm_fatal("MONITOR_CLASS",
                "Failed to get virtual mm_uvm_if from config DB. Check tb_top set() call.")
    endfunction : build_phase

    //  Connect Phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        `uvm_info("MONITOR_CLASS", "Connect Phase!", UVM_HIGH)
    endfunction : connect_phase

    //  Run Phase
    // Tasks to be defined for the run_phase to passively access data from DUT
    task run_phase(uvm_phase phase);
        `uvm_info("MONITOR_CLASS", "Inside Run Phase!", UVM_HIGH)

        forever begin

            // Create factory object for the transaction to be observed
            item = mm_seq_item::type_id::create("item");

            // Step 1: Detect start=1 pulse (new transaction start)
            @(posedge vif.clk iff (vif.rst_n && vif.start));
            `uvm_info("MONITOR_CLASS",
                "start=1 detected — new transaction beginning",
                UVM_MEDIUM)

            // Step 2: Capture N valid data cycles
            for (int k = 0; k < N; k++) begin

                @(posedge vif.clk iff (vif.ready && vif.valid_in_upstream));

                // Unpack flat a_in bus → column k of observed A
                // a_in[r*DW +: DW] = A[r][k]
                for (int r = 0; r < N; r++)
                    item.A[r][k] = vif.a_in[r*DATA_WIDTH +: DATA_WIDTH];

                // Unpack flat b_in bus → row k of observed B
                // b_in[c*DW +: DW] = B[k][c]
                for (int c = 0; c < N; c++)
                    item.B[k][c] = vif.b_in[c*DATA_WIDTH +: DATA_WIDTH];

                `uvm_info("MONITOR_CLASS",
                    $sformatf("  k=%0d captured: a_in=0x%0h  b_in=0x%0h",
                               k, vif.a_in, vif.b_in),
                    UVM_HIGH)
            end

            `uvm_info("MONITOR_CLASS",
                "All N cycles captured — reconstructed A and B",
                UVM_HIGH)

            // Step 3: Compute expected C = A × B from observed inputs
            item.compute_expected();
            `uvm_info("MONITOR_CLASS",
                "Expected C computed via reference model",
                UVM_HIGH)

            // Step 4: Wait for result_valid=1, capture DUT output
            @(posedge vif.clk iff (vif.rst_n && vif.result_valid));
            `uvm_info("MONITOR_CLASS",
                "result_valid=1 — capturing DUT result bus",
                UVM_MEDIUM)

            // Unpack 512-bit flat result bus → got_C[N][N]
            // Inverse of: result[(r*N+c)*ACCUM +: ACCUM] = result_wire[r][c]
            unpack_result(vif.result, item.got_C);

            // Step 5: Log full transaction and broadcast to scoreboard
            `uvm_info("MONITOR_CLASS",
                $sformatf("Transaction observed and packaged:%s",
                           item.convert2string()),
                UVM_MEDIUM)

            // Use write() method from monitor analysis port to broadcast
            // transaction to all connected subscribers (scoreboard)
            monitor_port.write(item);

        end
    endtask : run_phase

    //  unpack_result
    function automatic void unpack_result(
        input  logic [N*N*ACCUM_WIDTH-1:0] res_bus,
        output logic [ACCUM_WIDTH-1:0]     res_mat [N][N]
    );
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++)
`ifdef BUG3
                // BUG 3 (ACTIVE): Result bus unpacked with rows and columns
                // swapped — got_C stores the transpose of the actual DUT output.
                // RTL correctly computes A×B; reference model correctly predicts
                // A×B; but monitor reports got_C as (A×B)^T.
                // Scoreboard sees expected≠got_C for every non-symmetric result
                // and fires uvm_error — even though the RTL is correct.
                res_mat[c][r] = res_bus[(r*N+c)*ACCUM_WIDTH +: ACCUM_WIDTH];
`else
                res_mat[r][c] = res_bus[(r*N+c)*ACCUM_WIDTH +: ACCUM_WIDTH];
`endif
    endfunction : unpack_result

endclass : mm_monitor
