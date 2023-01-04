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
	input wire stallW,
	input wire we3,
	input wire[4:0] ra1,ra2,wa3,
	input wire[31:0] wd3,
	output wire[31:0] rd1,rd2
    );

	reg [31:0] rf[31:0];
	always @(posedge clk) begin
		// if(rst)begin
		// 	{rf[0],rf[1],rf[2],rf[3],rf[4],rf[5],rf[6],rf[7],
		// 	rf[8],rf[9],rf[10],rf[11],rf[12],rf[13],rf[14],rf[15],
		// 	rf[16],rf[17],rf[18],rf[19],rf[20],rf[21],rf[22],rf[23],
		// 	rf[24],rf[25],rf[26],rf[27],rf[28],rf[29],rf[30]} = {32{32'b0}};
		// end
		if(we3 & ~stallW) begin
			rf[wa3] <= wd3;
		end
	end

	assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
	assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule
