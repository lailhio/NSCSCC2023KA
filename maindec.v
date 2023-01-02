`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:21:30
// Design Name: 
// Module Name: maindec
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
`include"defines2.vh"

module maindec(
	input wire[5:0] op,

	output wire memtoreg,memwrite,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,
	output wire[3:0] aluop
    );
	reg[10:0] controls;
	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,aluop} = controls;
	always @(*) begin
		case (op)
			`R_TYPE :controls <= 11'b1100_000_1000;//R-TYRE
			`LW :controls <= 11'b1010_010_0100;//LW
			6'b101011 :controls <= 11'b0010_100_0100;//SW
			6'b000100 :controls <= 11'b0001_000_1011;//BEQ
			
			6'b001000 :controls <= 11'b1010_000_0100;//ADDI 
			6'b001001 :controls <= 11'b1010_000_0101;//ADDIU
			6'b001010 :controls <= 11'b1010_000_0110;//SLTI
			6'b001011 :controls <= 11'b1010_000_0111;//SLTIU  
			
			6'b001100 :controls <= 11'b1010_000_0000;//andi 
			6'b001110 :controls <= 11'b1010_000_0001;//xori 
			6'b001111 :controls <= 11'b1010_000_0010;//lui 
			6'b001101 :controls <= 11'b1010_000_0011;//ori 
			
			6'b000010 :controls <= 11'b0000_001_0100;//J
			default:  controls <= 11'b0000_000_1111;//illegal op
		endcase
	end
endmodule
