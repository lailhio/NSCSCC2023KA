`timescale 1ns / 1ps

`include "defines2.vh"


module maindec(
		input wire[31:0] instrD,


		output wire sign_exD,          //立即数是否为符号扩展
		output reg [1:0] regdstD,     	//写寄存器选择  00-> rd, 01-> rt, 10-> �?$ra
		output reg is_immD,        //alu srcb选择 0->rd2E, 1->immE
		output reg regwriteD,	//写寄存器堆使�?
		output wire hilo_wenD,
		output reg mem_readD, mem_writeD,
		output reg memtoregD,         	//result选择 0->alu_out, 1->read_data
		output wire hilo_to_regD,			// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
		output reg riD,
		output wire breakD, syscallD, eretD, 
		output wire cp0_wenD,
		output wire cp0_to_regD,
		output reg is_mfcD,   //为mfc0
		output reg [3:0] aluopD,
		output reg [2:0] branch_judge_controlD
    );

	//Instruct Divide
	wire [5:0] opD,functD;
	wire [4:0] rsD,rtD,rdD;
	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];

	assign sign_exD = (|(opD[5:2] ^ 4'b0011));		//0表示无符号拓展，1表示有符�?
	assign hilo_wenD = ~(|( opD^ `R_TYPE )) 		//首先判断是不是R-type
						& (~(|(functD[5:2] ^ 4'b0110)) 			// div divu mult multu 	
							|( ~(|(functD[5:2] ^ 4'b0100)) & functD[0]));

	assign hilo_to_regD = ~(|(opD ^ `R_TYPE)) & (~(|(functD[5:2] ^ 4'b0100)) & ~functD[0]);
														// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
	assign cp0_wenD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rsD ^ `MFC0));
	assign cp0_to_regD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rsD ^ `MTC0));
	assign eretD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rsD ^ `ERET));
	
	assign breakD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `BREAK));
	assign syscallD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `SYSCALL));

	always @(*) begin
		is_mfcD<=1'b0;
		riD<=1'b0;
		case(opD)
			`R_TYPE:begin
				case(functD)
					// 算数运算指令
					`ADD,`ADDU,`SUB,`SUBU,`SLTU,`SLT ,
					`AND,`NOR, `OR, `XOR,
					`SLLV, `SLL, `SRAV, `SRA, `SRLV, `SRL,
					`MFHI, `MFLO : begin
						aluopD<=`R_TYPE_OP;
						{regwriteD, regdstD, is_immD} =  4'b1000;
						{memtoregD, mem_readD, mem_writeD} =  3'b0;
					end
					// 乘除hilo、自陷�?�jr不需要使用寄存器和存储器
					`JR, `MULT, `MULTU, `DIV, `DIVU, `MTHI, `MTLO,
					`SYSCALL, `BREAK : begin
						aluopD<=`R_TYPE_OP;
						{regwriteD, regdstD, is_immD} =  4'b0;
						{memtoregD, mem_readD, mem_writeD} =  3'b0;
					end
					`JALR: begin
						aluopD<=`R_TYPE_OP;
						{regwriteD, regdstD, is_immD} =  4'b1100;//xxxxxxxx，感觉不太对�?
						{memtoregD, mem_readD, mem_writeD} =  3'b0;
					end
					default: begin
						aluopD<=`USELESS_OP;
						riD  =  1'b1;
						{regwriteD, regdstD, is_immD}  =  4'b1000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end
	// ------------------算数\逻辑运算--------------------------------------
			`ADDI:	begin
				aluopD<=`ADDI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`SLTI:	begin
				aluopD<=`SLTI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`SLTIU:	begin
				aluopD<=`SLTIU_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`ADDIU:	begin
				aluopD<=`ADDIU_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`ANDI:	begin
				aluopD<=`ADDI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`LUI:	begin
				aluopD<=`LUI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`XORI:	begin
				aluopD<=`XORI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`ORI:	begin
				aluopD<=`ORI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
	

			`BEQ, `BNE, `BLEZ, `BGTZ: begin
				aluopD<=`USELESS_OP;
				{regwriteD, regdstD, is_immD}  =  4'b0000;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end

			`REGIMM_INST: begin
				case(rtD)
					`BGEZAL,`BLTZAL: begin
						aluopD<=`USELESS_OP;
						{regwriteD, regdstD, is_immD}  =  4'b1100;//�?要写�?31
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`BGEZ,`BLTZ: begin
						aluopD<=`USELESS_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					default:begin
						riD  =  1'b1;
						aluopD<=`USELESS_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end
			
	// 访存指令，都是立即数指令�?
			`LW, `LB, `LBU, `LH, `LHU: begin
				aluopD<=`MEM_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b110;
			end
			`SW, `SB, `SH: begin
				aluopD<=`MEM_OP;
				{regwriteD, regdstD, is_immD}  =  4'b0001;
				{memtoregD, mem_readD, mem_writeD}  =  3'b001;
			end
	
	//  J type
			`J: begin
				aluopD<=`USELESS_OP;
				{regwriteD, regdstD, is_immD}  =  4'b0;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end

			`JAL: begin
				aluopD<=`USELESS_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1100;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end

			`SPECIAL3_INST:begin
				case(instrD[25:21])
					`MTC0: begin
						aluopD<=`MTC0_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`MFC0: begin
						aluopD<=`MFC0_OP;
						{regwriteD, regdstD, is_immD}  =  4'b1010;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
						is_mfcD = 1'b1;
					end
					default: begin
						aluopD<=`USELESS_OP;
						riD  =  |(instrD[25:0] ^ `ERET);
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end

			default: begin
				riD  =  1;
				aluopD<=`USELESS_OP;
				{regwriteD, regdstD, is_immD}  =  4'b0;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
		endcase
	end
	always @(*) begin
		case(opD)
			`BEQ: begin
				branch_judge_controlD<=3'b001;
			end
			`BNE: begin
				branch_judge_controlD<=3'b010;
			end
			`BLEZ: begin
				branch_judge_controlD<=3'b011;
			end
			`BGTZ: begin
				branch_judge_controlD<=3'b100;
			end
			`REGIMM_INST: begin
				case(rtD)
					`BLTZ,`BLTZAL: begin
						branch_judge_controlD<=3'b101;
					end
					`BGEZ,`BGEZAL: begin
						branch_judge_controlD<=3'b110;
					end
					default:begin
						branch_judge_controlD<=3'b101;
					end
				endcase
				end
			default:begin
						branch_judge_controlD<=3'b001;
					end
		endcase
	end
endmodule
