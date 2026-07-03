// controller.sv  —  FSM Controller for MM Accelerator

module controller #(
    parameter N = 4
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic valid_in_upstream,
    output logic ready,
    output logic valid_in,
    output logic result_valid,
    output logic clear
);

`ifdef BUG1
    // BUG 1 (ACTIVE): Off-by-one in drain counter.
    localparam int DRAIN_CYCLES = 2 * N - 1;
`else
    localparam int DRAIN_CYCLES = 2 * N;
`endif

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        LOAD  = 2'b01,
        DRAIN = 2'b10,
        DONE  = 2'b11
    } state_t;

    state_t state, next_state;

    logic [$clog2(N):0]             load_count;
    logic [$clog2(DRAIN_CYCLES):0]  drain_count;
    logic                           clear_reg;

    // State Register
    always_ff @(posedge clk or negedge rst_n) begin
        // VCS coverage off
        if (!rst_n) begin
            state <= IDLE;
        end else begin
        // VCS coverage on
            state <= next_state;
        // VCS coverage off
        end
        // VCS coverage on
    end

    // Next State Logic
    always_comb begin
        // Default next state
        next_state = state;

        case (state)
            IDLE: begin
                if (start) begin
                    next_state = LOAD;
                end else begin
                    next_state = IDLE;
                end
            end

            LOAD: begin
                // VCS coverage off
                if (valid_in_upstream && load_count == (N - 1)) begin
                // VCS coverage on
                    next_state = DRAIN;
                end else begin
                    next_state = LOAD;
                end
            end

            DRAIN: begin
                if (drain_count == 0) begin
                    next_state = DONE;
                end else begin
                    next_state = DRAIN;
                end
            end

            DONE: begin
                next_state = IDLE;
            end

            // VCS coverage off
            default: begin
                next_state = IDLE;
            end
            // VCS coverage on
        endcase
    end

    // Sequential Outputs & Counters
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_count  <= '0;
            drain_count <= '0;
            clear_reg   <= 1'b0;
        end else begin
            clear_reg <= 1'b0; // Default: de-assert clear

            case (state)
                IDLE: begin
                    if (start) begin
                        load_count <= '0;
                        clear_reg  <= 1'b1;
                    end else begin
                        load_count <= load_count;
                    end
                end

                LOAD: begin
                    if (valid_in_upstream) begin
                        if (load_count == (N - 1)) begin
                            drain_count <= DRAIN_CYCLES - 1;
                            load_count  <= load_count;
                        end else begin
                            load_count  <= load_count + 1'b1;
                            drain_count <= drain_count;
                        end
                    end else begin
                        load_count  <= load_count;
                        drain_count <= drain_count;
                    end
                end

                DRAIN: begin
                    if (drain_count != 0) begin
                        drain_count <= drain_count - 1'b1;
                    end else begin
                        drain_count <= drain_count;
                    end
                    load_count <= load_count;
                end
                
                DONE: begin
                    load_count <= load_count;
                    drain_count <= drain_count;
                end

                // VCS coverage off
                default: begin
                    load_count <= load_count;
                    drain_count <= drain_count;
                end
                // VCS coverage on
            endcase
        end
    end

    // Combinational outputs
    always_comb begin
        ready        = (state == LOAD);
        valid_in     = (state == LOAD) && valid_in_upstream;
        result_valid = (state == DONE);
        clear        = clear_reg;
    end

endmodule
