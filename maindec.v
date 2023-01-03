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
`include "defines2.vh"

module maindec(
	input wire[31:0] instrD,

	output wire memtoregD,memwriteD,
	output wire branchD,alusrcD,
	output wire regdstD,regwriteD,
	output wire jumpD,
	output wire[1:0] aluopD,
	output wire[2:0] fcD
    );
	//Declare
	wire [1:0] reg_dstD;
    wire alu_imm_selD, reg_writeD, mem_to_regD, mem_readD, mem_writeD;

    reg mem_to_regE, mem_read_enE, mem_write_enE;

	wire hilo_wenD, cp0_wenD;
	reg cp0_wenE;
	wire hilo_to_regD, cp0_to_regD;
	reg hilo_to_regE, cp0_to_regE;

	reg riD, riE;
	//自陷指令
	wire 	breakD, syscallD;
	reg 	breakE, syscallE;
	//中断返回
	wire 	eretD;
	reg 	eretE;

	//Instruct Divide
	wire [5:0] opD,functD;
	wire [4:0] rsD,rtD,rdD;
	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];

	//一部分能够容易判断的信号
	assign sign_extD = (|(opD[5:2] ^ 4'b0011));		//0表示无符号拓展
	assign hilo_wenD = ~(|( opD^ `R_TYPE )) 
						& (~(|(functD[5:2] ^ 4'b0110)) 			// div divu mult multu 	
							|( ~(|(functD[5:2] ^ 4'b0100)) & functD[0]) //mthi mtlo
						  );
	assign hilo_to_regD = ~(|(opD ^ `R_TYPE)) & (~(|(functD[5:2] ^ 4'b0100)) & ~functD[0]);
														// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
	assign cp0_wenD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rs ^ `MFC0));
	assign cp0_to_regD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rs ^ `MTC0));
	assign eretD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rs ^ `ERET));
	
	assign breakD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `BREAK));
	assign syscallD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `SYSCALL));

	always @(*) begin
		riD = 1'b0;
		case(op_code)
			`R_TYPE:
				case(funct)
					// 算数运算指令
					`EXE_ADD,`EXE_ADDU,`EXE_SUB,`EXE_SUBU,`EXE_SLTU,`EXE_SLT ,
					`EXE_AND,`EXE_NOR, `EXE_OR, `EXE_XOR,
					`EXE_SLLV, `EXE_SLL, `EXE_SRAV, `EXE_SRA, `EXE_SRLV, `EXE_SRL,
					`EXE_MFHI, `EXE_MFLO : begin
						regfile_ctrl 	 =  4'b1_00_0;
						mem_ctrl 		 =  3'b0;
					end
				endcase
		endcase
	end
endmodule
