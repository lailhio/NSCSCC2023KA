`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:20:09
// Design Name: 
// Module Name: regfile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module regfile(
	input wire clk,rst,
	input wire stall_masterW,
	input wire we3, we4,
	input wire[4:0] r1a1,r1a2, r2a1, r2a2, wa3, wa4,
	input wire[31:0] wd3, wd4,
	output wire[31:0] r1d1, r1d2, r2d1, r2d2
    );

	reg [31:0] rf[31:0];
	always @(posedge clk) begin
		if(rst) rf <= '{default: '0};
		else if(~stall_masterW) begin
			if(we3) rf[wa3] <= wd3;
			if(we4) rf[wa4] <= wd4;
		end
	end

	assign r1d1 = (r1a1 != 0) ? rf[r1a1] : 0;
	assign r1d2 = (r1a2 != 0) ? rf[r1a2] : 0;

	assign r2d1 = (r2a1 != 0) ? rf[r2a1] : 0;
	assign r2d2 = (r2a2 != 0) ? rf[r2a2] : 0;
endmodule
