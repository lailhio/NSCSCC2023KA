`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
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


module alu(
	input wire[31:0] a,b,
	input wire[4:0] sa,op,
	output reg[31:0] y,
	output reg overflow,
	output wire zero
    );
	
	always @(*) begin
		case (op)
		    //�߼�����
			5'b00111: y  = a & b;
			5'b00001: y  = a | b;
			5'b00010: y  = a ^ b;
			5'b00011: y  = ~( a | b );
			5'b00100: y  = {b[15:0],{16{1'b0}}};
			
			//��λ����
			5'b01000: y  = (b << sa);
			5'b01001: y  = (b >> sa);
			5'b01010: y  = ({32{b[31]}} << (6'd32-{1'b0,sa})) | b >> sa;
			5'b01011: y  = (b << a[4:0]);
			5'b01100: y  = (b >> a[4:0]);
			5'b01101: y  = ({32{b[31]}} << (6'd32-{1'b0,a[4:0]})) | b >> a[4:0];
			
			5'b10000: y  = a + b;
			
			default : y  = 32'b0;
		endcase	
	end
	assign zero = (y == 32'b0);

//	always @(*) begin
//		case (op[2:1])
//			2'b01:overflow  = a[31] & b[31] & ~s[31] |
//							~a[31] & ~b[31] & s[31];
//			2'b11:overflow  = ~a[31] & b[31] & s[31] |
//							a[31] & ~b[31] & ~s[31];
//			default : overflow  = 1'b0;
//		endcase	
//	end
endmodule
