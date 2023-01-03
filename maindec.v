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


module maindec(
	input wire[5:0] op,

	output wire memtoreg,memwrite,
	output wire branch,alusrc,
	output wire regdst,regwrite,
	output wire jump,
	output wire[1:0] aluop,
	output wire[2:0] fc
    );
	reg[11:0] controls;
	assign {regwrite,regdst,alusrc,branch,memwrite,memtoreg,jump,aluop,fc} = controls;
	always @(*) begin
		case (op)
			6'b000000:controls  = 12'b110000010_000;//R-TYRE
			6'b000100:controls  = 12'b000100001_000;//BEQ
			6'b001000:controls  = 12'b101000000_000;//ADDI
			
			6'b000010:controls  = 12'b000000100_000;//J
			
			//�߼�����
			6'b000000:controls  = 12'b110000010_000;//and
			6'b000000:controls  = 12'b110000010_000;//or
			6'b000000:controls  = 12'b110000010_000;//xor
			6'b000000:controls  = 12'b110000010_000;//nor
			6'b001100:controls  = 12'b101000000_000;//andi
			6'b001110:controls  = 12'b101000000_000;//xori
			6'b001111:controls  = 12'b101000000_000;//lui
			6'b001101:controls  = 12'b101000000_000;//ori
			
			//��λ����
			6'b000000:controls  = 12'b110000010_000;//sll
			6'b000000:controls  = 12'b110000010_000;//srl
			6'b000000:controls  = 12'b110000010_000;//sra
			6'b000000:controls  = 12'b110000010_000;//sllv
			6'b000000:controls  = 12'b110000010_000;//srlv
			6'b000000:controls  = 12'b110000010_000;//srav
			
			//�ô�
			6'b100000:controls  = 12'b101001000_000;//LB   000
			6'b100100:controls  = 12'b101001000_001;//LBU  001
			6'b100001:controls  = 12'b101001000_010;//LH   010
			6'b100101:controls  = 12'b101001000_011;//LHU  011
			6'b100011:controls  = 12'b101001000_100;//LW   100
			6'b101000:controls  = 12'b001010000_101;//SB   101	
			6'b101001:controls  = 12'b001010000_110;//SH   110
			6'b101011:controls  = 12'b001010000_111;//SW   111
			
			default:  controls  = 12'b000000000_000;//illegal op
		endcase
	end
endmodule
