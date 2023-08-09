`include "defines2.vh"

module maindec(
		input wire[31:0] instrD,
		input wire[31:0] instr2D,

		output reg only_oneD_inst,
		output reg read_rs, read_rt,
		output wire sign_ex,          //立即数是否为符号扩展
		output reg [1:0] regdst,     	//写寄存器选择  00-> rd, 01-> rt, 10-> ?$ra
		output reg is_imm,        //alu srcb选择 0->rd2E, 1->immE
		output reg regwrite,	//写寄存器堆使能
		output reg [4:0] writereg,
		output reg mem_read, mem_write,
		output reg memtoreg, hilo_write, hilo_read,
		output reg ri,
		output wire breaks, syscall, eret,
		output wire cp0_write,
		output wire cp0_read,
		
		output reg is_mfc, DivMulEn,
		output reg [2:0] branch_judge_control,
		output reg [7:0] alucontrol
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

	assign sign_ex = (|(opD[5:2] ^ 4'b0011));		//0表示无符号拓展，1表示有符号


	// 似乎只有这两条
	assign cp0_write = ~(|(opD ^ `COP0_INST)) & ~(|(rsD ^ `MTC0));
	assign cp0_read = ~(|(opD ^ `COP0_INST)) & ~(|(rsD ^ `MFC0));
	
	assign eret = ~(|(opD ^ `COP0_INST)) & ~(|(rsD ^ `ERET));
	assign breaks = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `BREAK));
	assign syscall = ~(|(opD ^ `R_TYPE)) & ~(|(functD ^ `SYSCALL));
	
	aludec alu_dec(functD, aluop, alucontrol);

	always @(*) begin
		case(opD)
			`R_TYPE:begin
				case (functD)
					`MULT, `MULTU, `DIV, `DIVU: 
						DivMulEn = 1'b1;
					default: DivMulEn = 1'b0;
				endcase
			end
			`SPECIAL2_INST:begin
				case (functD)
					`MUL, `MADD, `MADDU, `MSUB, `MSUBU:	
						DivMulEn = 1'b1;
					default: DivMulEn = 1'b0;
				endcase
			end
			default: DivMulEn = 1'b0;
		endcase
	end

	always @(*) begin
		case(opD)
			`R_TYPE:begin
				case (functD)
					`MFHI, `MFLO : 
						hilo_read = 1'b1;
					default: hilo_read = 1'b0;
				endcase
			end
			`SPECIAL2_INST:begin
				case (functD)
					`MADD, `MADDU, `MSUB, `MSUBU:	
						hilo_read = 1'b1;
					default: hilo_read = 1'b0;
				endcase
			end
			default: hilo_read = 1'b0;
		endcase
	end
	always @(*) begin
		case(opD)
			`R_TYPE:begin
				case (functD)
					`MTHI, `MTLO : 
						hilo_write = 1'b1;
					default: hilo_write = 1'b0;
				endcase
			end
			`SPECIAL2_INST:begin
				case (functD)
					`MADD, `MADDU, `MSUB, `MSUBU:	
						hilo_write = 1'b1;
					default: hilo_write = 1'b0;
				endcase
			end
			default: hilo_write = 1'b0;
		endcase
	end

	always @(*) begin
		only_oneD_inst = 1'b0;
		case(opD)
			`R_TYPE:begin
				is_mfc=1'b0;
				ri=1'b0;
				case(functD)
					// 算数运算指令
					`ADD,`ADDU,`SUB,`SUBU,`SLTU,`SLT ,
					`AND,`NOR, `OR, `XOR,
					`SLLV, `SLL, `SRAV, `SRA,
					`MOVN, `MOVZ,
					`MFHI, `MFLO : begin
						aluop=`R_TYPE_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm} =  4'b1000;
						{memtoreg, mem_read, mem_write} =  3'b0;
					end
					`SRL: begin
						// ROTR
						if(instrD[21]) begin
							aluop = `ROTR_OP;
							writereg = rdD;
							{regwrite, regdst, is_imm} =  4'b1000;
							{memtoreg, mem_read, mem_write} =  3'b0;
						end
						// SRL
						else begin
							aluop = `R_TYPE_OP;
							writereg = rdD;
							{regwrite, regdst, is_imm} =  4'b1000;
							{memtoreg, mem_read, mem_write} =  3'b0;
						end
					end
					`SRLV: begin
						// ROTRZ
						if(instrD[6]) begin
							aluop = `ROTRV_OP;
							writereg = rdD;
							{regwrite, regdst, is_imm} =  4'b1000;
							{memtoreg, mem_read, mem_write} =  3'b0;
						end
						// SRLV
						else begin
							aluop = `R_TYPE_OP;
							writereg = rdD;
							{regwrite, regdst, is_imm} =  4'b1000;
							{memtoreg, mem_read, mem_write} =  3'b0;
						end
					end
					// 乘除hilo、自陷、jr不需要使用寄存器和存储器
					`JR, `MULT, `MULTU, `DIV, `DIVU, `MTHI, `MTLO,
					`SYSCALL, `BREAK,
					`TEQ, `TGE, `TGEU, `TNE,
					`TLT, `TLTU : begin
						aluop=`R_TYPE_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm} =  4'b0;
						{memtoreg, mem_read, mem_write} =  3'b0;
					end
					`JALR: begin
						aluop=`R_TYPE_OP;
						writereg = 5'd31;
						{regwrite, regdst, is_imm} =  4'b1100;
						{memtoreg, mem_read, mem_write} =  3'b0;
					end
					default: begin
						aluop=`USELESS_OP;
						ri  =  1'b1;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b1000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
				endcase
			end
	// ------------------算数\逻辑运算--------------------------------------
			`ADDI:	begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`ADDI_OP;
				writereg = rtD;
				{regwrite, regdst, is_imm}  =  4'b1011;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end
			`SLTI:	begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`SLTI_OP;
				writereg = rtD;
				{regwrite, regdst, is_imm}  =  4'b1011;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end
			`SLTIU:	begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`SLTIU_OP;
				writereg = rtD;
				{regwrite, regdst, is_imm}  =  4'b1011;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end
			`ADDIU:	begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`ADDIU_OP;
				writereg = rtD;
				{regwrite, regdst, is_imm}  =  4'b1011;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end
			`ANDI:	begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`ANDI_OP;
				writereg = rtD;
				{regwrite, regdst, is_imm}  =  4'b1011;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end
			`LUI:	begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`LUI_OP;
				writereg = rtD;
				{regwrite, regdst, is_imm}  =  4'b1011;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end
			`XORI:	begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`XORI_OP;
				writereg = rtD;
				{regwrite, regdst, is_imm}  =  4'b1011;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end
			`ORI:	begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`ORI_OP;
				writereg = rtD;
				{regwrite, regdst, is_imm}  =  4'b1011;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end
	

			`BEQ, `BNE, `BLEZ, `BGTZ: begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`USELESS_OP;
				writereg = rdD;
				{regwrite, regdst, is_imm}  =  4'b0000;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end

			`REGIMM_INST: begin
				case(rtD)
					`BGEZAL,`BLTZAL: begin
						ri=1'b0;
						is_mfc=1'b0;
						aluop=`USELESS_OP;
						writereg = 5'd31;
						{regwrite, regdst, is_imm}  =  4'b1100;//要写31号寄存器
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`BGEZ,`BLTZ: begin
						ri=1'b0;
						is_mfc=1'b0;
						aluop=`USELESS_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`TEQI: begin
						ri=1'b0;
						is_mfc=1'b0;
						aluop=`TEQI_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`TGEI: begin
						ri=1'b0;
						is_mfc=1'b0;
						aluop=`TGEI_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`TGEIU: begin
						ri=1'b0;
						is_mfc=1'b0;
						aluop=`TGEIU_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`TLTI: begin
						ri=1'b0;
						is_mfc=1'b0;
						aluop=`TLTI_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`TLTIU: begin
						ri=1'b0;
						is_mfc=1'b0;
						aluop=`TLTIU_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`TNEI: begin
						ri=1'b0;
						is_mfc=1'b0;
						aluop=`TNEI_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					default:begin
						is_mfc=1'b0;
						ri  =  1'b1;
						aluop=`USELESS_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
				endcase
			end
			
	// 访存指令，都是立即数指令
			`LW, `LB, `LBU, `LH, `LHU, `LWL, `LWR, `LL: begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`MEM_OP;
				only_oneD_inst = 1;
				writereg = rtD;
				{regwrite, regdst, is_imm}  =  4'b1011;
				{memtoreg, mem_read, mem_write}  =  3'b110;
			end
			`SW, `SB, `SH, `SWL, `SWR: begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`MEM_OP;
				only_oneD_inst = 1;
				writereg = rdD;
				{regwrite, regdst, is_imm}  =  4'b0001;
				{memtoreg, mem_read, mem_write}  =  3'b001;
			end
			// `SC: begin
			// 	ri=1'b0;
			// 	is_mfc=1'b0;
			// 	aluop=`MEM_OP;
			// 	{regwrite, regdst, is_imm}  =  4'b1011;
			// 	{memtoreg, mem_read, mem_write}  =  3'b101;
			// end			

	
	//  J type
			`J: begin
				ri=1'b0;
				aluop=`USELESS_OP;
				is_mfc=1'b0;
				writereg = rdD;
				{regwrite, regdst, is_imm}  =  4'b0;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end

			`JAL: begin
				ri=1'b0;
				is_mfc=1'b0;
				aluop=`USELESS_OP;
				writereg = 5'd31;
				{regwrite, regdst, is_imm}  =  4'b1100;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end

			`COP0_INST:begin
				only_oneD_inst = 1;
				case(rsD)
					`MTC0: begin
						ri=1'b0;
						is_mfc=1'b0;
						aluop=`MTC0_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`MFC0: begin
						ri=1'b0;
						is_mfc = 1'b1;
						aluop=`MFC0_OP;
						writereg = rtD;
						{regwrite, regdst, is_imm}  =  4'b1010;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					default: begin
						is_mfc=1'b0;
						aluop=`USELESS_OP;
						writereg = rdD;
						ri  =  |(instrD[25:0] ^ `ERET);
						{regwrite, regdst, is_imm}  =  4'b0000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
				endcase
			end

			`SPECIAL2_INST: begin
				case(functD)
					`CLO: begin
						ri = 1'b0;
						is_mfc = 1'b0;
						aluop = `CLO_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b1000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`CLZ: begin
						ri = 1'b0;
						is_mfc = 1'b0;
						aluop = `CLZ_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b1000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`MUL: begin
						ri = 1'b0;
						is_mfc = 1'b0;
						aluop = `MUL_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b1000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`MADD:	begin
						ri = 1'b0;
						is_mfc = 1'b0;
						aluop = `MADD_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`MADDU:	begin
						ri = 1'b0;
						is_mfc = 1'b0;
						aluop = `MADDU_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`MSUB:	begin
						ri = 1'b0;
						is_mfc = 1'b0;
						aluop = `MSUB_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`MSUBU:	begin
						ri = 1'b0;
						is_mfc = 1'b0;
						aluop = `MSUBU_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					default: begin
						ri  =  1'b1;
						is_mfc=1'b0;
						aluop=`USELESS_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
				endcase
			end

			`SPECIAL3_INST: begin
				case(functD)
					`BSHFL: begin
						case(shamtD)
							`SEB: begin
								ri = 1'b0;
								is_mfc = 1'b0;
								aluop = `SEB_OP;
								writereg = rdD;
								{regwrite, regdst, is_imm}  =  4'b1000;
								{memtoreg, mem_read, mem_write}  =  3'b0;
							end
							`SEH: begin
								ri = 1'b0;
								is_mfc = 1'b0;
								aluop = `SEH_OP;
								writereg = rdD;
								{regwrite, regdst, is_imm}  =  4'b1000;
								{memtoreg, mem_read, mem_write}  =  3'b0;
							end
							`WSBH: begin
								ri = 1'b0;
								is_mfc = 1'b0;
								aluop = `WSBH_OP;
								writereg = rdD;
								{regwrite, regdst, is_imm}  =  4'b1000;
								{memtoreg, mem_read, mem_write}  =  3'b0;
							end
							default: begin
								ri  =  1'b1;
								is_mfc=1'b0;
								aluop=`USELESS_OP;
								writereg = rdD;
								{regwrite, regdst, is_imm}  =  4'b0000;
								{memtoreg, mem_read, mem_write}  =  3'b0;
							end
						endcase
					end
					`EXT: begin
						ri = 1'b0;
						is_mfc = 1'b0;
						aluop = `EXT_OP;
						writereg = rtD;
						{regwrite, regdst, is_imm}  =  4'b1010;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					`INS: begin
						ri = 1'b0;
						is_mfc = 1'b0;
						aluop = `INS_OP;
						writereg = rtD;
						{regwrite, regdst, is_imm}  =  4'b1010;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
					default: begin
						ri  =  1'b1;
						is_mfc=1'b0;
						aluop=`USELESS_OP;
						writereg = rdD;
						{regwrite, regdst, is_imm}  =  4'b0000;
						{memtoreg, mem_read, mem_write}  =  3'b0;
					end
				endcase
			end

			default: begin
				ri  =  1;
				is_mfc=1'b0;
				aluop =`USELESS_OP;
				writereg = rdD;
				{regwrite, regdst, is_imm}  =  4'b0;
				{memtoreg, mem_read, mem_write}  =  3'b0;
			end
		endcase
		if(!instr2D)begin
			only_oneD_inst = 0;
		end
	end
	always @(*) begin
		case(opD)
			`BEQ: begin
				branch_judge_control=3'b001;
			end
			`BNE: begin
				branch_judge_control=3'b010;
			end
			`BLEZ: begin
				branch_judge_control=3'b011;
			end
			`BGTZ: begin
				branch_judge_control=3'b100;
			end
			`REGIMM_INST: begin
				case(rtD)
					`BLTZ,`BLTZAL: begin
						branch_judge_control=3'b101;
					end
					`BGEZ,`BGEZAL: begin
						branch_judge_control=3'b110;
					end
					default:begin
						branch_judge_control=3'b101;
					end
				endcase
				end
			default:begin
						branch_judge_control=3'b000;
					end
		endcase
	end

	// read_rs\rt
	always @(*) begin
		case(opD)
            // R
			`R_TYPE:begin
				case(functD)
					`MULT, `MULTU, `DIV, `DIVU, `TEQ, `TGE, `TGEU, `TNE, `TLT, `TLTU,
					`ADD , `ADDU , `SUB , `SUBU , `SLTU , `SLT , `AND , `NOR , `OR , `XOR , `SLLV,
					`SRAV, `MOVN, `MOVZ, `SRLV : begin
						read_rs = 1'b1;
						read_rt = 1'b1;
					end
					`SLL, `SRL, `SRA: begin
                        read_rs = 1'b0;
						read_rt = 1'b1;
					end
					`MFHI , `SYSCALL, `BREAK, `MFLO:  begin
                        read_rs = 1'b0;
                        read_rt = 1'b0;
					end
					`JR , `MTHI , `MTLO, `JALR: begin
						read_rs = 1'b1;
                        read_rt = 1'b0;
					end
					default: begin
                        read_rs = 1'b0;
                        read_rt = 1'b0;
					end
				endcase
			end

	        // 运算// 访存指令，写寄存器
			`LUI, `J, `JAL: begin
				read_rs = 1'b0;
				read_rt = 1'b0;
			end
			`ADDI, `ADDIU, `SLTI, `SLTIU, `ANDI, `XORI, `ORI, `BGTZ, `BLEZ,
			`LW , `LB , `LBU , `LH , `LHU , `LWL , `LWR , `LL:	begin
				read_rs = 1'b1;
				read_rt = 1'b0;
			end
			`BEQ, `BNE, `SW, `SB, `SH, `SWL, `SWR: begin
				read_rs = 1'b1;
                read_rt = 1'b1;
            end

            // 移位
			`REGIMM_INST: begin
				case(rtD)
					`BGEZAL, `BLTZAL, `BGEZ, `BLTZ, `TEQI, `TGEI, `TGEIU, `TLTI,
					`TLTIU, `TNEI: begin
						read_rs = 1'b1;
                		read_rt = 1'b0;
					end
					default:begin
                        read_rs = 1'b0;
                		read_rt = 1'b0;
					end
				endcase
			end

            // COP0
			`COP0_INST:begin
				case(rsD)
					`MTC0: begin
                        read_rs = 1'b0;
						read_rt = 1'b1;
					end
					//注意eret
					default: begin
                        read_rs = 1'b0;
                		read_rt = 1'b0;
					end
				endcase
			end

            // 特殊指令
			`SPECIAL2_INST: begin
				case(functD)
					`CLO, `CLZ: begin
						read_rs = 1'b1;
                		read_rt = 1'b0;
					end
					`MUL, `MADD, `MADDU, `MSUB, `MSUBU: begin
						read_rs = 1'b1;
						read_rt = 1'b1;
					end
					default: begin
                        read_rs = 1'b0;
                		read_rt = 1'b0;
					end
				endcase
			end
            // 特殊指令
			`SPECIAL3_INST: begin
				case(functD)
					`BSHFL: begin
						case(shamtD)
							`SEB, `SEH, `WSBH: begin
                       			read_rs = 1'b0;
								read_rt = 1'b1;
							end
							default: begin
                       			read_rs = 1'b0;
								read_rt = 1'b0;
							end
						endcase
					end
					`EXT: begin
						read_rs = 1'b1;
						read_rt = 1'b0;
					end
					`INS: begin
						read_rs = 1'b1;
						read_rt = 1'b1;
					end
					default: begin
						read_rs = 1'b0;
						read_rt = 1'b0;
					end
				endcase
			end
			default: begin
				read_rs = 1'b0;
				read_rt = 1'b0;
			end
		endcase
		if(!instrD) begin
			read_rs = 1'b0;
			read_rt = 1'b0;
		end
	end
endmodule