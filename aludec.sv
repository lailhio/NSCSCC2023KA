`include "defines2.vh"

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

			`ROTR_OP:	alucontrol = `ROTR_CONTROL;
			default:
						alucontrol = 8'b0;
		endcase
	end
	
endmodule
