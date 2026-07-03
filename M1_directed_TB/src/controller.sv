module controller #(
        parameter N = 4
)(
        input  logic clk, rst_n,
        input  logic start,
        input  logic valid_in_upstream,
        output logic ready,
        output logic valid_in,
        output logic result_valid,
	output logic clear
);

// total cycles to wait after last input for pipeline to drain
localparam DRAIN_CYCLES = 2*N;

// FSM state encoding
typedef enum logic [1:0] {
        IDLE  = 2'b00,
        LOAD  = 2'b01,
        DRAIN = 2'b10,
        DONE  = 2'b11
} state_t;

state_t state;

// counters
logic [$clog2(N)-1:0]            load_count;
logic [$clog2(DRAIN_CYCLES)-1:0] drain_count;

// FSM sequential logic
always_ff @(posedge clk) begin
        if (!rst_n) begin
                state       <= IDLE;
                load_count  <= '0;
                drain_count <= '0;

        end else begin
                case (state)

                        IDLE: begin
				clear <= 1'b0;
                                if (start) begin
                                        state      <= LOAD;
                                        load_count <= '0;
					clear <= 1'b1;
                                end
                        end

                        LOAD: begin
				clear <= 1'b0;
                                if (valid_in_upstream) begin
                                        load_count <= load_count + 1;

                                        if (load_count == N-1) begin  // fed N cycles of data
                                                state       <= DRAIN;
                                                drain_count <= DRAIN_CYCLES - 1;
                                        end
                                end
                        end

                        DRAIN: begin
				clear <= 1'b0;
                                drain_count <= drain_count - 1;

                                if (drain_count == 0) begin
                                        state <= DONE;
                                end
                        end

                        DONE: begin
				clear <= 1'b0;
                                state <= IDLE;  // result_valid pulses one cycle then returns to IDLE
                        end

                        default: state <= IDLE;

                endcase
        end
end

// combinational output logic
always_comb begin
        ready        = (state == LOAD);
        valid_in     = (state == LOAD) && valid_in_upstream;
        result_valid = (state == DONE);
end

endmodule
