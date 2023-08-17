//flip-flop with enable,rst,clear
module flopsf #(parameter WIDTH = 8)(
	input wire clk,rst,stall,flush,
	input wire[WIDTH-1:0] in,
	output reg[WIDTH-1:0] out
    );
	always @(posedge clk) begin
		if(rst) begin
			out <= 0;
		end else if(~stall) begin
			/* code */
			out <= in;
		end
        else if(flush)begin
            out <= 0;
        end
        else begin
            out <= out;
        end
	end
endmodule