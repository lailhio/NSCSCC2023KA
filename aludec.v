`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/10/23 15:27:24
// Design Name: 
// Module Name: aludec
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


module aludec(
	input wire[5:0] op,
	input wire[5:0] funct,
	output reg[4:0] alucontrol
    );
	always @(*) begin
	    case (op)
	       6'b000000: 
	           case (funct)
	               //�߼�����
                   6'b100100:alucontrol  = 5'b00111;//and
                   6'b100101:alucontrol  = 5'b00001;//or
                   6'b100110:alucontrol  = 5'b00010;//xor
                   6'b100111:alucontrol  = 5'b00011;//nor
                   
                   //��λ����
                   6'b000000:alucontrol  = 5'b01000;//sll
                   6'b000010:alucontrol  = 5'b01001;//srl
                   6'b000011:alucontrol  = 5'b01010;//sra
                   6'b000100:alucontrol  = 5'b01011;//sllv
                   6'b000110:alucontrol  = 5'b01100;//srlv
                   6'b000111:alucontrol  = 5'b01101;//srav
                   
                   
                   default: alucontrol  = 5'b00000;
               endcase
           6'b001100:alucontrol  = 5'b00111;//andi
           6'b001110:alucontrol  = 5'b00010;//xori
           6'b001111:alucontrol  = 5'b00100;//lui
           6'b001101:alucontrol  = 5'b00001;//ori
           
            //�ô�
			6'b100000:alucontrol  = 5'b10000;//LB
			6'b100100:alucontrol  = 5'b10000;//LBU
			6'b100001:alucontrol  = 5'b10000;//LH
			6'b100101:alucontrol  = 5'b10000;//LHU
			6'b100011:alucontrol  = 5'b10000;//LW
			6'b101000:alucontrol  = 5'b10000;//SB
			6'b101001:alucontrol  = 5'b10000;//SH
			6'b101011:alucontrol  = 5'b10000;//SW
           
           default: alucontrol  = 5'b00000;
       endcase
	end
endmodule
