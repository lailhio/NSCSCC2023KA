`include "defines2.vh"
`timescale 1ns / 1ps

module aludec(
	input wire[5:0] funct,
	input wire[5:0] aluop,
	output reg[7:0] alucontrol
    );
	always @(*) begin
		case (aluop)
            `R_TYPE_OP: 
				case(funct)
					//算数和逻辑运算
					`AND:   	alucontrol = `AND_CONTROL; //1
					`OR:    	alucontrol = `OR_CONTROL;
					`XOR:   	alucontrol = `XOR_CONTROL;
					`NOR:   	alucontrol = `NOR_CONTROL;

					`ADD:   	alucontrol = `ADD_CONTROL;	//4
					`SUB:   	alucontrol = `SUB_CONTROL;
					`ADDU:  	alucontrol = `ADDU_CONTROL;
					`SUBU:  	alucontrol = `SUBU_CONTROL;
					`SLT:   	alucontrol = `SLT_CONTROL;
					`SLTU:  	alucontrol = `SLTU_CONTROL;
						//div and mul
					`DIV:   	alucontrol = `DIV_CONTROL;
					`DIVU:  	alucontrol = `DIVU_CONTROL;
					`MULT:  	alucontrol = `MULT_CONTROL;
					`MULTU: 	alucontrol = `MULTU_CONTROL;

					//移位指令
					`SLL:   	alucontrol = `SLL_CONTROL;	//2
					`SRL:   	alucontrol = `SRL_CONTROL;
					`SRA:   	alucontrol = `SRA_CONTROL;
					`SLLV:  	alucontrol = `SLLV_CONTROL;
					`SRLV:  	alucontrol = `SRLV_CONTROL;
					`SRAV:  	alucontrol = `SRAV_CONTROL;

					//hilo
					`MTHI:  	alucontrol = `MTHI_CONTROL;
					`MTLO:  	alucontrol = `MTLO_CONTROL;
					`MFHI:      alucontrol = `MFHI_CONTROL;
					`MFLO:      alucontrol = `MFLO_CONTROL;

					//conditional move
					`MOVN:		alucontrol = `MOVN_CONTROL;
					`MOVZ:		alucontrol = `MOVZ_CONTROL;

					//trap
					`TEQ:		alucontrol = `TEQ_CONTROL;
					`TGE:		alucontrol = `TGE_CONTROL;
					`TGEU:		alucontrol = `TGEU_CONTROL;
					`TLT:		alucontrol = `TLT_CONTROL;
					`TLTU:		alucontrol = `TLTU_CONTROL;
					`TNE:		alucontrol = `TNE_CONTROL;

					default:    	alucontrol = 8'b00000000;
				endcase
			//I type
			`ADDI_OP: 	alucontrol = `ADD_CONTROL;
			`ADDIU_OP: alucontrol = `ADDU_CONTROL;
			`SLTI_OP: 	alucontrol = `SLT_CONTROL;
			`SLTIU_OP: alucontrol = `SLTU_CONTROL;
			`ANDI_OP: 	alucontrol = `AND_CONTROL;
			`XORI_OP: alucontrol = `XOR_CONTROL;
			`LUI_OP: 	alucontrol = `LUI_CONTROL;
			`ORI_OP: alucontrol = `OR_CONTROL;

			//additional
			`CLO_OP:	alucontrol = `CLO_CONTROL;
			`CLZ_OP:	alucontrol = `CLZ_CONTROL;

			`SEB_OP: 	alucontrol = `SEB_CONTROL;
			`SEH_OP:	alucontrol = `SEH_CONTROL;
			`WSBH_OP:	alucontrol = `WSBH_CONTROL;

			`ROTR_OP:	alucontrol = `ROTR_CONTROL;
			`ROTRV_OP: 	alucontrol = `ROTRV_CONTROL;

			`EXT_OP:	alucontrol = `EXT_CONTROL;
			`INS_OP:	alucontrol = `INS_CONTROL;

			`MADD_OP:	alucontrol = `MADD_CONTROL;
			`MADDU_OP:	alucontrol = `MADDU_CONTROL;
			`MSUB_OP:	alucontrol = `MSUB_CONTROL;
			`MSUBU_OP:	alucontrol = `MSUBU_CONTROL;

			`MUL_OP:	alucontrol = `MUL_CONTROL;

			`TEQI_OP:	alucontrol = `TEQI_CONTROL;
			`TGEI_OP:	alucontrol = `TGEI_CONTROL;
			`TGEIU_OP:	alucontrol = `TGEIU_CONTROL;
			`TLTI_OP:	alucontrol = `TLTI_CONTROL;
			`TLTIU_OP:	alucontrol = `TLTIU_CONTROL;
			`TNEI_OP:	alucontrol = `TNEI_CONTROL;

			default:
						alucontrol = 8'b0;
		endcase
	end
	
endmodule
