`include "defines2.vh"

module maindec(
		input wire[31:0] instrD,

		output wire sign_exD,          //立即数是否为符号扩展
		output reg [1:0] regdstD,     	//写寄存器选择  00-> rd, 01-> rt, 10-> ?$ra
		output reg is_immD,        //alu srcb选择 0->rd2E, 1->immE
		output reg regwriteD,	//写寄存器堆使能
		output reg mem_readD, mem_writeD,
		output reg memtoregD,         	//result选择 0->aluout, 1->read_data
		output wire hilotoregD,			// 00--aluoutM; 01--hilo_out; 10 11--rdataM;
		output reg riD,
		output wire breakD, syscallD, eretD,
		output wire cp0_writeD,
		output wire cp0_to_regD,
			
		output wire mfhiD,
		output wire mfloD,
		output reg is_mfcD,   //为mfc0
		output reg [5:0] aluopD,
		output reg [5:0] funct_to_aluD,
		output reg [2:0] branch_judge_controlD,
		output reg DivMulEnD
    );

	//Instruct Divide
	wire [5:0] opD,functD;
	wire [4:0] rsD,rtD,rdD,shamtD;
	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign shamtD = instrD[10:6];

	assign sign_exD = (|(opD[5:2] ^ 4'b0011));		//0表示无符号拓展，1表示有符号

	assign hilotoregD = (opD == `R_TYPE) & (~(|(functD[5:2] ^ 4'b0100)) & ~functD[0]);
														// 00--aluoutM; 01--hilo_out; 10 11--rdataM;
	assign mfhiD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `MFHI));
	assign mfloD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `MFLO));
	assign cp0_writeD = ~(|(opD ^ `COP0_INST)) & ~(|(rsD ^ `MTC0));
	assign cp0_to_regD = ~(|(opD ^ `COP0_INST)) & ~(|(rsD ^ `MFC0));
	assign eretD = ~(|(opD ^ `COP0_INST)) & ~(|(rsD ^ `ERET));
	
	assign breakD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `BREAK));
	assign syscallD = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `SYSCALL));

	always @(*) begin
		case(opD)
			`R_TYPE:begin
				case (functD)
					`MULT, `MULTU, `DIV, `DIVU: 
						DivMulEnD = 1'b1;
					default: DivMulEnD = 1'b0;
				endcase
			end
			`SPECIAL2_INST:begin
				case (functD)
					`MUL, `MADD, `MADDU, `MSUB, `MSUBU:	
						DivMulEnD = 1'b1;
					default: DivMulEnD = 1'b0;
				endcase
			end
			default: DivMulEnD = 1'b0;
		endcase
	end
	always @(*) begin
		case(opD)
			`R_TYPE:begin
				is_mfcD=1'b0;
				riD=1'b0;
				case(functD)
					// 算数运算指令
					`ADD,`ADDU,`SUB,`SUBU,`SLTU,`SLT ,
					`AND,`NOR, `OR, `XOR,
					`SLLV, `SLL, `SRAV, `SRA,
					`MOVN, `MOVZ,
					`MFHI, `MFLO : begin
						aluopD=`R_TYPE_OP;
						{regwriteD, regdstD, is_immD} =  4'b1000;
						{memtoregD, mem_readD, mem_writeD} =  3'b0;
					end
					`SRL: begin
						// ROTR
						if(instrD[21]) begin
							aluopD = `ROTR_OP;
							{regwriteD, regdstD, is_immD} =  4'b1000;
							{memtoregD, mem_readD, mem_writeD} =  3'b0;
						end
						// SRL
						else begin
							aluopD = `R_TYPE_OP;
							{regwriteD, regdstD, is_immD} =  4'b1000;
							{memtoregD, mem_readD, mem_writeD} =  3'b0;
						end
					end
					`SRLV: begin
						// ROTRZ
						if(instrD[6]) begin
							aluopD = `ROTRV_OP;
							{regwriteD, regdstD, is_immD} =  4'b1000;
							{memtoregD, mem_readD, mem_writeD} =  3'b0;
						end
						// SRLV
						else begin
							aluopD = `R_TYPE_OP;
							{regwriteD, regdstD, is_immD} =  4'b1000;
							{memtoregD, mem_readD, mem_writeD} =  3'b0;
						end
					end
					// 乘除hilo、自陷、jr不需要使用寄存器和存储器
					`JR, `MULT, `MULTU, `DIV, `DIVU, `MTHI, `MTLO,
					`SYSCALL, `BREAK,
					`TEQ, `TGE, `TGEU, `TNE,
					`TLT, `TLTU : begin
						aluopD=`R_TYPE_OP;
						{regwriteD, regdstD, is_immD} =  4'b0;
						{memtoregD, mem_readD, mem_writeD} =  3'b0;
					end
					`JALR: begin
						aluopD=`R_TYPE_OP;
						{regwriteD, regdstD, is_immD} =  4'b1100;
						{memtoregD, mem_readD, mem_writeD} =  3'b0;
					end
					default: begin
						aluopD=`USELESS_OP;
						riD  =  1'b1;
						{regwriteD, regdstD, is_immD}  =  4'b1000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end
	// ------------------算数\逻辑运算--------------------------------------
			`ADDI:	begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`ADDI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`SLTI:	begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`SLTI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`SLTIU:	begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`SLTIU_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`ADDIU:	begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`ADDIU_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`ANDI:	begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`ANDI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`LUI:	begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`LUI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`XORI:	begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`XORI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
			`ORI:	begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`ORI_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
	

			`BEQ, `BNE, `BLEZ, `BGTZ: begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`USELESS_OP;
				{regwriteD, regdstD, is_immD}  =  4'b0000;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end

			`REGIMM_INST: begin
				case(rtD)
					`BGEZAL,`BLTZAL: begin
						riD=1'b0;
						is_mfcD=1'b0;
						aluopD=`USELESS_OP;
						{regwriteD, regdstD, is_immD}  =  4'b1100;//要写31号寄存器
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`BGEZ,`BLTZ: begin
						riD=1'b0;
						is_mfcD=1'b0;
						aluopD=`USELESS_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`TEQI: begin
						riD=1'b0;
						is_mfcD=1'b0;
						aluopD=`TEQI_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`TGEI: begin
						riD=1'b0;
						is_mfcD=1'b0;
						aluopD=`TGEI_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`TGEIU: begin
						riD=1'b0;
						is_mfcD=1'b0;
						aluopD=`TGEIU_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`TLTI: begin
						riD=1'b0;
						is_mfcD=1'b0;
						aluopD=`TLTI_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`TLTIU: begin
						riD=1'b0;
						is_mfcD=1'b0;
						aluopD=`TLTIU_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`TNEI: begin
						riD=1'b0;
						is_mfcD=1'b0;
						aluopD=`TNEI_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					default:begin
						is_mfcD=1'b0;
						riD  =  1'b1;
						aluopD=`USELESS_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end
			
	// 访存指令，都是立即数指令
			`LW, `LB, `LBU, `LH, `LHU, `LWL, `LWR, `LL: begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`MEM_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1011;
				{memtoregD, mem_readD, mem_writeD}  =  3'b110;
			end
			`SW, `SB, `SH, `SWL, `SWR: begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`MEM_OP;
				{regwriteD, regdstD, is_immD}  =  4'b0001;
				{memtoregD, mem_readD, mem_writeD}  =  3'b001;
			end
			// `SC: begin
			// 	riD=1'b0;
			// 	is_mfcD=1'b0;
			// 	aluopD=`MEM_OP;
			// 	{regwriteD, regdstD, is_immD}  =  4'b1011;
			// 	{memtoregD, mem_readD, mem_writeD}  =  3'b101;
			// end			

	
	//  J type
			`J: begin
				riD=1'b0;
				aluopD=`USELESS_OP;
				is_mfcD=1'b0;
				{regwriteD, regdstD, is_immD}  =  4'b0;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end

			`JAL: begin
				riD=1'b0;
				is_mfcD=1'b0;
				aluopD=`USELESS_OP;
				{regwriteD, regdstD, is_immD}  =  4'b1100;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end

			`COP0_INST:begin
				case(rsD)
					`MTC0: begin
						riD=1'b0;
						is_mfcD=1'b0;
						aluopD=`MTC0_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`MFC0: begin
						riD=1'b0;
						is_mfcD = 1'b1;
						aluopD=`MFC0_OP;
						{regwriteD, regdstD, is_immD}  =  4'b1010;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					default: begin
						is_mfcD=1'b0;
						aluopD=`USELESS_OP;
						riD  =  |(instrD[25:0] ^ `ERET);
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end

			`SPECIAL2_INST: begin
				case(functD)
					`CLO: begin
						riD = 1'b0;
						is_mfcD = 1'b0;
						aluopD = `CLO_OP;
						{regwriteD, regdstD, is_immD}  =  4'b1000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`CLZ: begin
						riD = 1'b0;
						is_mfcD = 1'b0;
						aluopD = `CLZ_OP;
						{regwriteD, regdstD, is_immD}  =  4'b1000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`MUL: begin
						riD = 1'b0;
						is_mfcD = 1'b0;
						aluopD = `MUL_OP;
						{regwriteD, regdstD, is_immD}  =  4'b1000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`MADD:	begin
						riD = 1'b0;
						is_mfcD = 1'b0;
						aluopD = `MADD_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`MADDU:	begin
						riD = 1'b0;
						is_mfcD = 1'b0;
						aluopD = `MADDU_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`MSUB:	begin
						riD = 1'b0;
						is_mfcD = 1'b0;
						aluopD = `MSUB_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`MSUBU:	begin
						riD = 1'b0;
						is_mfcD = 1'b0;
						aluopD = `MSUBU_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					default: begin
						riD  =  1'b1;
						is_mfcD=1'b0;
						aluopD=`USELESS_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end

			`SPECIAL3_INST: begin
				case(functD)
					`BSHFL: begin
						case(shamtD)
							`SEB: begin
								riD = 1'b0;
								is_mfcD = 1'b0;
								aluopD = `SEB_OP;
								{regwriteD, regdstD, is_immD}  =  4'b1000;
								{memtoregD, mem_readD, mem_writeD}  =  3'b0;
							end
							`SEH: begin
								riD = 1'b0;
								is_mfcD = 1'b0;
								aluopD = `SEH_OP;
								{regwriteD, regdstD, is_immD}  =  4'b1000;
								{memtoregD, mem_readD, mem_writeD}  =  3'b0;
							end
							`WSBH: begin
								riD = 1'b0;
								is_mfcD = 1'b0;
								aluopD = `WSBH_OP;
								{regwriteD, regdstD, is_immD}  =  4'b1000;
								{memtoregD, mem_readD, mem_writeD}  =  3'b0;
							end
							default: begin
								riD  =  1'b1;
								is_mfcD=1'b0;
								aluopD=`USELESS_OP;
								{regwriteD, regdstD, is_immD}  =  4'b0000;
								{memtoregD, mem_readD, mem_writeD}  =  3'b0;
							end
						endcase
					end
					`EXT: begin
						riD = 1'b0;
						is_mfcD = 1'b0;
						aluopD = `EXT_OP;
						{regwriteD, regdstD, is_immD}  =  4'b1010;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					`INS: begin
						riD = 1'b0;
						is_mfcD = 1'b0;
						aluopD = `INS_OP;
						{regwriteD, regdstD, is_immD}  =  4'b1010;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
					default: begin
						riD  =  1'b1;
						is_mfcD=1'b0;
						aluopD=`USELESS_OP;
						{regwriteD, regdstD, is_immD}  =  4'b0000;
						{memtoregD, mem_readD, mem_writeD}  =  3'b0;
					end
				endcase
			end

			default: begin
				riD  =  1;
				is_mfcD=1'b0;
				aluopD =`USELESS_OP;
				{regwriteD, regdstD, is_immD}  =  4'b0;
				{memtoregD, mem_readD, mem_writeD}  =  3'b0;
			end
		endcase
		funct_to_aluD=functD;
	end
	always @(*) begin
		case(opD)
			`BEQ: begin
				branch_judge_controlD=3'b001;
			end
			`BNE: begin
				branch_judge_controlD=3'b010;
			end
			`BLEZ: begin
				branch_judge_controlD=3'b011;
			end
			`BGTZ: begin
				branch_judge_controlD=3'b100;
			end
			`REGIMM_INST: begin
				case(rtD)
					`BLTZ,`BLTZAL: begin
						branch_judge_controlD=3'b101;
					end
					`BGEZ,`BGEZAL: begin
						branch_judge_controlD=3'b110;
					end
					default:begin
						branch_judge_controlD=3'b101;
					end
				endcase
				end
			default:begin
						branch_judge_controlD=3'b000;
					end
		endcase
	end
endmodule