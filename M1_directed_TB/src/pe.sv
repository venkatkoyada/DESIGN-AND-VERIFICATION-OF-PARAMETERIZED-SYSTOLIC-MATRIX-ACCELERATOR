module pe # (
	parameter DATA_WIDTH  = 8,
	parameter ACCUM_WIDTH = 32 
)(
	input  logic			 clk, rst_n,
	input  logic [DATA_WIDTH-1:0]	 a_in, b_in,
	output logic [DATA_WIDTH-1:0]	 a_out, b_out, 
	output logic [ACCUM_WIDTH-1:0]	 accum,
	input  logic			 valid_in,
	output logic			 valid_out,
	input  logic			 clear
);

always @(posedge clk)
	if(!rst_n) begin
		a_out	  <= 0;
		b_out	  <= 0;
		accum	  <= 0;
		valid_out <= 1'b0;
	end	
	else begin
		valid_out <= valid_in;
	
		a_out	  <= a_in;
		b_out	  <= b_in;
		if(clear) begin
			accum <= '0;
		end else if (valid_in) begin
			accum <= accum + a_in * b_in;
		end
	end
endmodule
