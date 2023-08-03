`include "defines2.vh"

module maindec(
		input wire[31:0] instrD,

		output ctrl_sign dec_sign,
		output reg only_oneD_inst
    );
			

	//Instruct Divide
	reg [5:0] aluop;
	wire [5:0] opD,functD;
	wire [4:0] rsD,rtD,rdD,shamtD;

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign shamtD = instrD[10:6];

	assign dec_sign.sign_ex = (|(opD[5:2] ^ 4'b0011));		//0表示无符号拓展，1表示有符号

	assign dec_sign.hilo_read_to_reg = ~(|(opD ^ `R_TYPE)) & (~(|(functD[5:2] ^ 4'b0100)) & ~functD[0]);
														// 00--aluoutM; 01--hilo_out; 10 11--rdataM;
	assign dec_sign.mfhi = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `MFHI));
	assign dec_sign.mflo = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `MFLO));
	assign dec_sign.cp0_write = ~(|(opD ^ `COP0_INST)) & ~(|(rsD ^ `MTC0));
	assign dec_sign.cp0_read_to_reg = ~(|(opD ^ `COP0_INST)) & ~(|(rsD ^ `MFC0));
	assign dec_sign.eret = ~(|(opD ^ `COP0_INST)) & ~(|(rsD ^ `ERET));
	
	assign dec_sign.breaks = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `BREAK));
	assign dec_sign.syscall = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `SYSCALL));
	
	aludec alu_dec(functD, aluop, dec_sign.alucontrol);

	always @(*) begin
		case(opD)
			`R_TYPE:begin
				case (functD)
					`MULT, `MULTU, `DIV, `DIVU: 
						dec_sign.DivMulEn = 1'b1;
					default: dec_sign.DivMulEn = 1'b0;
				endcase
			end
			`SPECIAL2_INST:begin
				case (functD)
					`MUL, `MADD, `MADDU, `MSUB, `MSUBU:	
						dec_sign.DivMulEn = 1'b1;
					default: dec_sign.DivMulEn = 1'b0;
				endcase
			end
			default: dec_sign.DivMulEn = 1'b0;
		endcase
	end
	always @(*) begin
		only_oneD_inst = 1'b0;
		case(opD)
			`R_TYPE:begin
				dec_sign.is_mfc=1'b0;
				dec_sign.ri=1'b0;
				case(functD)
					// 算数运算指令
					`ADD,`ADDU,`SUB,`SUBU,`SLTU,`SLT ,
					`AND,`NOR, `OR, `XOR,
					`SLLV, `SLL, `SRAV, `SRA,
					`MOVN, `MOVZ,
					`MFHI, `MFLO : begin
						aluop=`R_TYPE_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm} =  4'b1000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write} =  3'b0;
					end
					`SRL: begin
						// ROTR
						if(instrD[21]) begin
							aluop = `ROTR_OP;
							{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm} =  4'b1000;
							{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write} =  3'b0;
						end
						// SRL
						else begin
							aluop = `R_TYPE_OP;
							{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm} =  4'b1000;
							{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write} =  3'b0;
						end
					end
					`SRLV: begin
						// ROTRZ
						if(instrD[6]) begin
							aluop = `ROTRV_OP;
							{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm} =  4'b1000;
							{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write} =  3'b0;
						end
						// SRLV
						else begin
							aluop = `R_TYPE_OP;
							{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm} =  4'b1000;
							{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write} =  3'b0;
						end
					end
					// 乘除hilo、自陷、jr不需要使用寄存器和存储器
					`JR, `MULT, `MULTU, `DIV, `DIVU, `MTHI, `MTLO,
					`SYSCALL, `BREAK,
					`TEQ, `TGE, `TGEU, `TNE,
					`TLT, `TLTU : begin
						aluop=`R_TYPE_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm} =  4'b0;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write} =  3'b0;
					end
					`JALR: begin
						aluop=`R_TYPE_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm} =  4'b1100;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write} =  3'b0;
					end
					default: begin
						aluop=`USELESS_OP;
						dec_sign.ri  =  1'b1;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
				endcase
			end
	// ------------------算数\逻辑运算--------------------------------------
			`ADDI:	begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`ADDI_OP;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1011;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end
			`SLTI:	begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`SLTI_OP;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1011;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end
			`SLTIU:	begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`SLTIU_OP;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1011;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end
			`ADDIU:	begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`ADDIU_OP;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1011;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end
			`ANDI:	begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`ANDI_OP;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1011;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end
			`LUI:	begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`LUI_OP;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1011;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end
			`XORI:	begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`XORI_OP;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1011;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end
			`ORI:	begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`ORI_OP;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1011;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end
	

			`BEQ, `BNE, `BLEZ, `BGTZ: begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`USELESS_OP;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end

			`REGIMM_INST: begin
				case(rtD)
					`BGEZAL,`BLTZAL: begin
						dec_sign.ri=1'b0;
						dec_sign.is_mfc=1'b0;
						aluop=`USELESS_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1100;//要写31号寄存器
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`BGEZ,`BLTZ: begin
						dec_sign.ri=1'b0;
						dec_sign.is_mfc=1'b0;
						aluop=`USELESS_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`TEQI: begin
						dec_sign.ri=1'b0;
						dec_sign.is_mfc=1'b0;
						aluop=`TEQI_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`TGEI: begin
						dec_sign.ri=1'b0;
						dec_sign.is_mfc=1'b0;
						aluop=`TGEI_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`TGEIU: begin
						dec_sign.ri=1'b0;
						dec_sign.is_mfc=1'b0;
						aluop=`TGEIU_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`TLTI: begin
						dec_sign.ri=1'b0;
						dec_sign.is_mfc=1'b0;
						aluop=`TLTI_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`TLTIU: begin
						dec_sign.ri=1'b0;
						dec_sign.is_mfc=1'b0;
						aluop=`TLTIU_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`TNEI: begin
						dec_sign.ri=1'b0;
						dec_sign.is_mfc=1'b0;
						aluop=`TNEI_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					default:begin
						dec_sign.is_mfc=1'b0;
						dec_sign.ri  =  1'b1;
						aluop=`USELESS_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
				endcase
			end
			
	// 访存指令，都是立即数指令
			`LW, `LB, `LBU, `LH, `LHU, `LWL, `LWR, `LL: begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`MEM_OP;
				only_oneD_inst = 1;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1011;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b110;
			end
			`SW, `SB, `SH, `SWL, `SWR: begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`MEM_OP;
				only_oneD_inst = 1;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0001;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b001;
			end
			// `SC: begin
			// 	dec_sign.ri=1'b0;
			// 	dec_sign.is_mfc=1'b0;
			// 	aluop=`MEM_OP;
			// 	{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1011;
			// 	{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b101;
			// end			

	
	//  J type
			`J: begin
				dec_sign.ri=1'b0;
				aluop=`USELESS_OP;
				dec_sign.is_mfc=1'b0;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end

			`JAL: begin
				dec_sign.ri=1'b0;
				dec_sign.is_mfc=1'b0;
				aluop=`USELESS_OP;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1100;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end

			`COP0_INST:begin
				only_oneD_inst = 1;
				case(rsD)
					`MTC0: begin
						dec_sign.ri=1'b0;
						dec_sign.is_mfc=1'b0;
						aluop=`MTC0_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`MFC0: begin
						dec_sign.ri=1'b0;
						dec_sign.is_mfc = 1'b1;
						aluop=`MFC0_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1010;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					default: begin
						dec_sign.is_mfc=1'b0;
						aluop=`USELESS_OP;
						dec_sign.ri  =  |(instrD[25:0] ^ `ERET);
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
				endcase
			end

			`SPECIAL2_INST: begin
				case(functD)
					`CLO: begin
						dec_sign.ri = 1'b0;
						dec_sign.is_mfc = 1'b0;
						aluop = `CLO_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`CLZ: begin
						dec_sign.ri = 1'b0;
						dec_sign.is_mfc = 1'b0;
						aluop = `CLZ_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`MUL: begin
						dec_sign.ri = 1'b0;
						dec_sign.is_mfc = 1'b0;
						aluop = `MUL_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`MADD:	begin
						dec_sign.ri = 1'b0;
						dec_sign.is_mfc = 1'b0;
						aluop = `MADD_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`MADDU:	begin
						dec_sign.ri = 1'b0;
						dec_sign.is_mfc = 1'b0;
						aluop = `MADDU_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`MSUB:	begin
						dec_sign.ri = 1'b0;
						dec_sign.is_mfc = 1'b0;
						aluop = `MSUB_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`MSUBU:	begin
						dec_sign.ri = 1'b0;
						dec_sign.is_mfc = 1'b0;
						aluop = `MSUBU_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					default: begin
						dec_sign.ri  =  1'b1;
						dec_sign.is_mfc=1'b0;
						aluop=`USELESS_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
				endcase
			end

			`SPECIAL3_INST: begin
				case(functD)
					`BSHFL: begin
						case(shamtD)
							`SEB: begin
								dec_sign.ri = 1'b0;
								dec_sign.is_mfc = 1'b0;
								aluop = `SEB_OP;
								{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1000;
								{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
							end
							`SEH: begin
								dec_sign.ri = 1'b0;
								dec_sign.is_mfc = 1'b0;
								aluop = `SEH_OP;
								{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1000;
								{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
							end
							`WSBH: begin
								dec_sign.ri = 1'b0;
								dec_sign.is_mfc = 1'b0;
								aluop = `WSBH_OP;
								{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1000;
								{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
							end
							default: begin
								dec_sign.ri  =  1'b1;
								dec_sign.is_mfc=1'b0;
								aluop=`USELESS_OP;
								{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
								{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
							end
						endcase
					end
					`EXT: begin
						dec_sign.ri = 1'b0;
						dec_sign.is_mfc = 1'b0;
						aluop = `EXT_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1010;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					`INS: begin
						dec_sign.ri = 1'b0;
						dec_sign.is_mfc = 1'b0;
						aluop = `INS_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b1010;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
					default: begin
						dec_sign.ri  =  1'b1;
						dec_sign.is_mfc=1'b0;
						aluop=`USELESS_OP;
						{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0000;
						{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
					end
				endcase
			end

			default: begin
				dec_sign.ri  =  1;
				dec_sign.is_mfc=1'b0;
				aluop =`USELESS_OP;
				{dec_sign.regwrite, dec_sign.regdst, dec_sign.is_imm}  =  4'b0;
				{dec_sign.memtoreg, dec_sign.mem_read, dec_sign.mem_write}  =  3'b0;
			end
		endcase
	end
	always @(*) begin
		case(opD)
			`BEQ: begin
				dec_sign.branch_judge_control=3'b001;
			end
			`BNE: begin
				dec_sign.branch_judge_control=3'b010;
			end
			`BLEZ: begin
				dec_sign.branch_judge_control=3'b011;
			end
			`BGTZ: begin
				dec_sign.branch_judge_control=3'b100;
			end
			`REGIMM_INST: begin
				case(rtD)
					`BLTZ,`BLTZAL: begin
						dec_sign.branch_judge_control=3'b101;
					end
					`BGEZ,`BGEZAL: begin
						dec_sign.branch_judge_control=3'b110;
					end
					default:begin
						dec_sign.branch_judge_control=3'b101;
					end
				endcase
				end
			default:begin
						dec_sign.branch_judge_control=3'b000;
					end
		endcase
	end

	// read_rs\rt
	always @(*) begin
        dec_sign.read_rs = 1'b1;
        dec_sign.read_rt = 1'b0;
		case(opD)
            // R
			`R_TYPE:begin
                dec_sign.read_rt = 1'b1;
				case(functD)
					// 算数运算指令
					`ADD : begin
					end
                    `ADDU : begin
					end
                    `SUB : begin
					end
                    `SUBU : begin
					end
                    `SLTU : begin
					end
                    `SLT  : begin
					end
					`AND : begin
					end
                    `NOR : begin
					end
                    `OR : begin
					end
                    `XOR : begin
					end
					`SLLV : begin
					end
                    `SLL : begin
                        dec_sign.read_rs = 1'b0;
					end
                    `SRAV : begin
					end
                    `SRA : begin
                        dec_sign.read_rs = 1'b0;
					end
					`MOVN : begin
					end
                    `MOVZ : begin
					end
					`MFHI : begin
                        dec_sign.read_rs = 1'b0;
                        dec_sign.read_rt = 1'b0;
					end
                     `MFLO : begin
                        dec_sign.read_rs = 1'b0;
                        dec_sign.read_rt = 1'b0;
					end
					`SRL: begin
						dec_sign.read_rs = 1'b0;
					end
					`SRLV: begin
					end
					// 乘除hilo、自陷、jr不需要使用寄存器和存储器
					`JR : begin
                        dec_sign.read_rt = 1'b0;
					end
                    `MULT : begin
					end
                    `MULTU : begin
					end
                    `DIV : begin
					end
                    `DIVU : begin
					end
                    `MTHI : begin
                        dec_sign.read_rt = 1'b0;
					end
                    `MTLO : begin
                        dec_sign.read_rt = 1'b0;
					end
					`SYSCALL : begin
                        dec_sign.read_rs = 1'b0;
                        dec_sign.read_rt = 1'b0;
					end
                    `BREAK : begin
                        dec_sign.read_rs = 1'b0;
                        dec_sign.read_rt = 1'b0;
					end
					`TEQ : begin
					end
                    `TGE : begin
					end
                    `TGEU : begin
					end
                    `TNE : begin
					end
					`TLT : begin
					end
                    `TLTU : begin
					end
					`JALR: begin
						dec_sign.read_rt = 1'b0;
					end
					default: begin
                        dec_sign.read_rs = 1'b0;
                        dec_sign.read_rt = 1'b0;
					end
				endcase
			end

	        // 运算
			`ADDI:	begin
			end
            `ADDIU:	begin
			end
			`SLTI:	begin
			end
			`SLTIU:	begin
			end
			`ANDI:	begin
			end
			`LUI:	begin
                dec_sign.read_rs = 1'b0;
			end
			`XORI:	begin
			end
			`ORI:	begin
			end
			`BEQ : begin
                dec_sign.read_rt = 1'b1;
            end
            `BNE : begin
                dec_sign.read_rt = 1'b1;
            end
            `BLEZ : begin
            end
            `BGTZ: begin
			end

            // 移位
			`REGIMM_INST: begin
				case(rtD)
					`BGEZAL : begin
					end
                    `BLTZAL: begin
					end
					`BGEZ: begin
					end
                    `BLTZ: begin
					end
					`TEQI: begin
					end
					`TGEI: begin
					end
					`TGEIU: begin
					end
					`TLTI: begin
					end
					`TLTIU: begin
					end
					`TNEI: begin
					end
					default:begin
                        dec_sign.read_rs = 1'b0;
					end
				endcase
			end
			
	        // 访存指令，写寄存器
			`LW: begin
                dec_sign.read_rs = 1'b0;
			end
            `LB: begin
                dec_sign.read_rs = 1'b0;
			end
            `LBU: begin
                dec_sign.read_rs = 1'b0;
			end
            `LH: begin
                dec_sign.read_rs = 1'b0;
			end
            `LHU: begin
                dec_sign.read_rs = 1'b0;
			end
            `LWL: begin
                dec_sign.read_rs = 1'b0;
			end
            `LWR: begin
                dec_sign.read_rs = 1'b0;
			end
            `LL: begin
                dec_sign.read_rs = 1'b0;
			end
            // 访存指令，读寄存器
			`SW: begin
                dec_sign.read_rs = 1'b0;
                dec_sign.read_rt = 1'b1;
			end
            `SB: begin
                dec_sign.read_rs = 1'b0;
                dec_sign.read_rt = 1'b1;
			end
            `SH: begin
                dec_sign.read_rs = 1'b0;
                dec_sign.read_rt = 1'b1;
			end
            `SWL: begin
                dec_sign.read_rs = 1'b0;
                dec_sign.read_rt = 1'b1;
			end
            `SWR: begin
				dec_sign.read_rs = 1'b0;
                dec_sign.read_rt = 1'b1;
			end
			// `SC: begin
			// 	dec_sign.read_rs = 1'b0;
            //  dec_sign.read_rt = 1'b1;
			// end			

	        //  J type
			`J: begin
				dec_sign.read_rs = 1'b0;
			end
			`JAL: begin
				dec_sign.read_rs = 1'b0;
			end

            // COP0
			`COP0_INST:begin
				case(rsD)
					`MTC0: begin
                        dec_sign.read_rs = 1'b0;
						dec_sign.read_rt = 1'b1;
					end
					`MFC0: begin
						dec_sign.read_rs = 1'b0;
					end
					default: begin
                        dec_sign.read_rs = 1'b0;
					end
				endcase
			end

            // 特殊指令
			`SPECIAL2_INST: begin
				case(functD)
					`CLO: begin
					end
					`CLZ: begin
					end
					`MUL: begin
						dec_sign.read_rt = 1'b1;
					end
					`MADD:	begin
						dec_sign.read_rt = 1'b1;
					end
					`MADDU:	begin
						dec_sign.read_rt = 1'b1;
					end
					`MSUB:	begin
						dec_sign.read_rt = 1'b1;
					end
					`MSUBU:	begin
						dec_sign.read_rt = 1'b1;
					end
					default: begin
                        dec_sign.read_rs = 1'b0;
					end
				endcase
			end

            // 特殊指令
			`SPECIAL3_INST: begin
				case(functD)
					`BSHFL: begin
                        dec_sign.read_rs = 1'b0;
						dec_sign.read_rt = 1'b1;
						case(shamtD)
							`SEB: begin
							end
							`SEH: begin
							end
							`WSBH: begin
							end
							default: begin
								dec_sign.read_rt = 1'b0;
							end
						endcase
					end
					`EXT: begin
					end
					`INS: begin
						dec_sign.read_rt = 1'b1;
					end
					default: begin
						dec_sign.read_rs = 1'b0;
					end
				endcase
			end

			default: begin
				dec_sign.read_rs = 1'b0;
			end
		endcase
	end
endmodule