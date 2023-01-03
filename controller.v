`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: controller
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


module controller(
	input wire clk,rst,
	//decode stage
	input wire[5:0] opD,functD,
	output wire pcsrcD,branchD,equalD,jumpD,
	
	//execute stage
	input wire flushE,
	output wire memtoregE,alusrcE,
	output wire regdstE,regwriteE,	
	output wire[4:0] alucontrolE,

	//mem stage
	output wire memtoregM,memwriteM,
				regwriteM,
	output wire[2:0] fcM,
	//write back stage
	output wire memtoregW,regwriteW,
	output wire[2:0] fcW

    );
	
	//decode stage
	wire[1:0] aluopD;
	wire memtoregD,memwriteD,alusrcD,
		regdstD,regwriteD;
	wire[4:0] alucontrolD;
	wire[2:0] fcD;

	//execute stage
	wire memwriteE;
	wire[2:0] fcE;
	
	maindec md(
		opD,
		memtoregD,memwriteD,
		branchD,alusrcD,
		regdstD,regwriteD,
		jumpD,
		aluopD,
		fcD
		);
	aludec ad(opD,functD,alucontrolD);

	assign pcsrcD = branchD & equalD;

	//pipeline registers
	floprc #(13) regE(
		clk,
		rst,
		flushE,
		{memtoregD,memwriteD,alusrcD,regdstD,regwriteD,alucontrolD,fcD},
		{memtoregE,memwriteE,alusrcE,regdstE,regwriteE,alucontrolE,fcE}
		);
	flopr #(6) regM(
		clk,rst,
		{memtoregE,memwriteE,regwriteE,fcE},
		{memtoregM,memwriteM,regwriteM,fcM}
		);
	flopr #(5) regW(
		clk,rst,
		{memtoregM,regwriteM,fcM},
		{memtoregW,regwriteW,fcW}
		);
endmodule
