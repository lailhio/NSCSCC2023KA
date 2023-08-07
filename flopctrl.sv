`timescale 1ns / 1ps
//flip-flop with enable,rst,clear
module flopctrl(
	input wire clk,rst,stall,flush,
	input ctrl_sign in,
	output ctrl_sign out
    );
	always @(posedge clk) begin
		if(rst | flush) begin
			out <= 0;
		end else if(~stall) begin
			/* code */
			out <= in;
		end
	end
endmodule