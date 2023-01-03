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

`include "defines2.vh"
module aludec(
	input wire[5:0] funct,
	input wire[3:0] aluop,
	output reg[4:0] alucontrol
    );
	always @(*) begin
		case (aluop)
            `R_TYPE_OP: 
				case(funct)
					//算数和逻辑运算
					`AND:   	alucontrol <= `AND_CONTROL; //1
					`OR:    	alucontrol <= `OR_CONTROL;
					`XOR:   	alucontrol <= `XOR_CONTROL;
					`NOR:   	alucontrol <= `NOR_CONTROL;

					`ADD:   	alucontrol <= `ADD_CONTROL;	//4
					`SUB:   	alucontrol <= `SUB_CONTROL;
					`ADDU:  	alucontrol <= `ADDU_CONTROL;
					`SUBU:  	alucontrol <= `SUBU_CONTROL;
					`SLT:   	alucontrol <= `SLT_CONTROL;
					`SLTU:  	alucontrol <= `SLTU_CONTROL;
						//div and mul
					`DIV:   	alucontrol <= `DIV_CONTROL;
					`DIVU:  	alucontrol <= `DIV_CONTROL;
					`MULT:  	alucontrol <= `MULT_CONTROL;
					`MULTU: 	alucontrol <= `MULT_CONTROL;

					//移位指令
					`SLL:   	alucontrol <= `SLL_CONTROL;	//2
					`SRL:   	alucontrol <= `SRL_CONTROL;
					`SRA:   	alucontrol <= `SRA_CONTROL;
					`SLLV:  	alucontrol <= `SLLV_CONTROL;
					`SRLV:  	alucontrol <= `SRLV_CONTROL;
					`SRAV:  	alucontrol <= `SRAV_CONTROL;

					//hilo
					`MTHI:  	alucontrol <= `MTHI_CONTROL;
					`MTLO:  	alucontrol <= `MTLO_CONTROL;
					//jump
					// `EXE_JR:		alu_control <= `ALU_DONOTHING; //5
					// `EXE_JALR:	alu_control <= `ALU_DONOTHING;
					default:    	alucontrol <= 5'b00000;
				endcase
			//I type
			`ADDI_OP: 	alucontrol <= `ADD_CONTROL;
			`ADDIU_OP: alucontrol <= `ADDU_CONTROL;
			`SLTI_OP: 	alucontrol <= `SLT_CONTROL;
			`SLTIU_OP: alucontrol <= `SLTU_CONTROL;
			`ANDI_OP: 	alucontrol <= `AND_CONTROL;
			`XORI_OP: alucontrol <= `XOR_CONTROL;
			`LUI_OP: 	alucontrol <= `LUI_CONTROL;
			`ORI_OP: alucontrol <= `OR_CONTROL;
				//memory
			`LW, `LB, `LBU, `LH, `LHU, `SW, `SB, `SH:
						alucontrol <= `ADDU_CONTROL;
			// `EXE_BEQ:
            //     alu_controlD <= `ALU_EQ;
            // `EXE_BGTZ:
            //     alu_controlD <= `ALU_GTZ;
            // `EXE_BLEZ:   
            //     alu_controlD <= `ALU_LEZ;
            // `EXE_BNE:
            //     alu_controlD <= `ALU_NEQ;
            // `EXE_BRANCHS:   //bltz, bltzal, bgez, bgezal
            //     case(rt)
            //         `EXE_BLTZ, `EXE_BLTZAL:      
            //             alu_controlD <= `ALU_LTZ;
            //         `EXE_BGEZ, `EXE_BGEZAL: 
            //             alu_controlD <= `ALU_GEZ;
            //         default:
            //             alu_controlD <= `ALU_DONOTHING; 
            //     endcase	
			//J type
			// `EXE_J:		alu_controlD <= `ALU_DONOTHING;
			// `EXE_JAL:	alu_controlD <= `ALU_DONOTHING;
			default:
						alucontrol <= 5'b0;
		endcase
	end
	
endmodule
