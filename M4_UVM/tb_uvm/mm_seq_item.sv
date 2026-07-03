// mm_seq_item.sv  —  UVM Sequence Item for MM Accelerator
//
// Represents one complete N×N matrix-multiply transaction.
// Follows ECE-593 UVM pattern:
//   - extends uvm_sequence_item
//   - `uvm_object_utils for factory registration (object type, one arg)
//   - rand fields on inputs, non-rand fields on outputs
//   - Standard UVM constructor
//
// corner_mode distribution steers coverage:
//   0 (70%) = fully random   1 (10%) = all-zero A
//   2 (10%) = identity A     3 (10%) = all-max A & B

class mm_seq_item extends uvm_sequence_item;

    // ── UVM Factory Registration (object type → one argument) ────────────
    `uvm_object_utils(mm_seq_item)

    // ── Fixed Parameters matching DUT mm_accelerator_top ─────────────────
    localparam int N           = 4;
    localparam int DATA_WIDTH  = 8;
    localparam int ACCUM_WIDTH = 32;

    // ── Randomizable Input Fields ─────────────────────────────────────────
    rand logic [DATA_WIDTH-1:0]  A [N][N];     // N×N input matrix A
    rand logic [DATA_WIDTH-1:0]  B [N][N];     // N×N input matrix B
    rand logic [1:0]             corner_mode;  // stimulus pattern selector

    // ── Non-rand Output Fields (written externally) ───────────────────────
    logic [ACCUM_WIDTH-1:0] C     [N][N];  // expected output — set by compute_expected()
    logic [ACCUM_WIDTH-1:0] got_C [N][N];  // actual DUT output — filled by monitor

    // ── Constraints on Inputs ─────────────────────────────────────────────

    // Weighted distribution: 70% random, 30% corner cases
    constraint c_corner_dist {
        corner_mode dist { 2'b00 := 70,
                           2'b01 := 10,
                           2'b10 := 10,
                           2'b11 := 10 };
    }

    // All randomized values stay in valid 8-bit range
    constraint c_data_range {
        foreach (A[r,c]) A[r][c] inside {[8'h00 : 8'hFF]};
        foreach (B[r,c]) B[r][c] inside {[8'h00 : 8'hFF]};
    }

    // ── Standard UVM Constructor ──────────────────────────────────────────
    function new(string name = "mm_seq_item");
        super.new(name);
    endfunction : new

    // ── Post-Randomize: apply corner overrides then compute reference ──────
    // Called automatically by randomize(); overrides A/B before sending to DUT.
    function void post_randomize();
        case (corner_mode)
            2'b01: begin                            // all-zero A → C must be zero
                foreach (A[r,c]) A[r][c] = '0;
            end
            2'b10: begin                            // identity A → C must equal B
                foreach (A[r,c]) A[r][c] = (r == c) ? 8'd1 : 8'd0;
            end
            2'b11: begin                            // max A and B → accumulator overflow corner
                foreach (A[r,c]) A[r][c] = {DATA_WIDTH{1'b1}};
                foreach (B[r,c]) B[r][c] = {DATA_WIDTH{1'b1}};
            end
            default: ;                              // 2'b00: keep fully random values
        endcase
        compute_expected();
    endfunction : post_randomize

    // ── Reference Model: C = A × B ────────────────────────────────────────
    // Must be called after A and B are finalised.
    // Scoreboard also calls this directly when it reconstructs A/B from monitor.
    function void compute_expected();
        for (int r = 0; r < N; r++)
            for (int c = 0; c < N; c++) begin
                C[r][c] = '0;
                for (int k = 0; k < N; k++)
                    C[r][c] += ACCUM_WIDTH'(A[r][k]) * ACCUM_WIDTH'(B[k][c]);
            end
    endfunction : compute_expected

    // ── convert2string: used by `uvm_info for full transaction logging ─────
    function string convert2string();
        string s;
        s = $sformatf("\n  [SEQ_ITEM] corner_mode=%0d", corner_mode);
        for (int r = 0; r < N; r++) begin
            s = {s, $sformatf("\n    A[%0d]=[", r)};
            for (int c = 0; c < N; c++)
                s = {s, $sformatf("%4d", A[r][c])};
            s = {s, $sformatf(" ]  B[%0d]=[", r)};
            for (int c = 0; c < N; c++)
                s = {s, $sformatf("%4d", B[r][c])};
            s = {s, " ]"};
        end
        s = {s, "\n  Expected C:"};
        for (int r = 0; r < N; r++) begin
            s = {s, $sformatf("\n    C[%0d]=[", r)};
            for (int c = 0; c < N; c++)
                s = {s, $sformatf("%8d", C[r][c])};
            s = {s, " ]"};
        end
        return s;
    endfunction : convert2string

endclass : mm_seq_item
