//TODO:LL,LWL,LWR,MADD.MADDU,MOVN,MOVZ,MSUB,MSUBU
//TODO:MTC0?,MTC0?
`include "defines2.vh"

module main_decoder(
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
		output reg [7:0] alucontrolD,
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

	assign sign_exD = (|(opD[5:2] ^ 4'b0011));		//0表示无符号拓展，1表示有符号

	assign hilotoregD = ~(|(opD ^ `R_SPECIAL)) & (~(|(functD[5:2] ^ 4'b0100)) & ~functD[0]);
														// 00--aluoutM; 01--hilo_out; 10 11--rdataM;
	assign mfhiD = ~(|(opD ^ `R_SPECIAL)) & ~(|(functD ^ `MFHI));
	assign mfloD = ~(|(opD ^ `R_SPECIAL)) & ~(|(functD ^ `MFLO));
	assign cp0_writeD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rsD ^ `MTC0));
	assign cp0_to_regD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rsD ^ `MFC0));
	assign eretD = ~(|(opD ^ `SPECIAL3_INST)) & ~(|(rsD ^ `ERET));
	
	assign breakD = ~(|(opD ^ `R_SPECIAL)) & ~(|(functD ^ `BREAK_FUNCT));
	assign syscallD = ~(|(opD ^ `R_SPECIAL)) & ~(|(functD ^ `SYSCALL));
    
    //riD
    always @(instrD) begin
        case(opD)
            `REGIMM_SPRCIAL:begin
                case(rtD)
                    `BGEZAL_SHAMT,`BGEZ_SHAMT,`BLTZAL_SHAMT,
                    `BLTZ_SHAMT: riD=1'b0;
                    default: riD=1'b1;
                endcase
            end
            `COP0_SPECIAL: begin
                case(rsD)
                    `MFC0_SHAMT,`MTC0_SHAMT: riD=1'b0;
                    default: riD=|(instrD[25:0] ^ `ERET);
                endcase
            end
            default: riD=1'b0;
        endcase
    end
    
    //is_mfcD
    always @(instrD) begin
        case(opD)
            `COP0_SPECIAL: begin
                case(rsD)
                    `MFC0_SHAMT: is_mfcD=1'b1;
                    default: is_mfcD=1'b0;
                endcase
            end
            default: is_mfcD=1'b0;
        endcase
    end
    
    //regdstD
    always @(instrD) begin
        case(opD)
            `R_SPECIAL:begin
                case(functD)
                    `JALR_SPECIAL: regdstD=2'b10;
                    default: regdstD=2'b00;
                endcase
            end
            `REGIMM_SPRCIAL:begin
                case(rtD)
                    `BGEZAL_SHAMT,`BLTZAL_SHAMT: regdstD=2'b10;
                    default: regdstD=2'b00;
                endcase
            end
            `ADDI_SPECIAL,`ADDIU_SPECIAL,`ANDI_SPECIAL, 
            `LW_SPECIAL, `LB_SPECIAL, `LBU_SPECIAL, 
            `LH_SPECIAL, `LHU_SPECIAL, `LUI_SPECIAL, 
            `SLTI_SPECIAL, `SLTIU_SPECIAL, `XORI_SPECIAL,
            `ORI_SPECIAL: regdstD=2'b01;
            `JAL_SPECIAL: regdstD=2'b10;

            default: regdstD=2'b00;
        endcase
    end
    
    //is_immD
    always @(instrD) begin
        case(opD)
            `ADDI_SPECIAL,`ADDIU_SPECIAL,`ANDI_SPECIAL, 
            `LW_SPECIAL, `LB_SPECIAL, `LBU_SPECIAL, 
            `LH_SPECIAL, `LHU_SPECIAL, `LUI_SPECIAL, 
            `SLTI_SPECIAL, `SLTIU_SPECIAL, `XORI_SPECIAL,
            `ORI_SPECIAL,`SW_SPECIAL, `SB_SPECIAL, `SH_SPECIAL: is_immD=1'b1;
            default: is_immD=1'b0;
        endcase
    end
    
    //regwriteD
    always @(instrD) begin
        case(opD)
            `R_SPECIAL: begin
                case(functD)
                    `JR_FUNCT, `MULT_FUNCT, `MULTU_FUNCT, 
                    `DIV_FUNCT, `DIVU_FUNCT, `MTHI_FUNCT, 
                    `MTLO_FUNCT, `SYSCALL_FUNCT, `BREAK_FUNCT, 6'b000000 : regwriteD=1'b0;
                    default: regwriteD=1'b1;
                endcase
            end
            `SPECIAL2:begin
                case(functD)
                    `CLO_FUNCT, `CLZ_FUNCT: regwriteD=1'b1;
                    default: regwriteD=1'b0;
                endcase
            end
            `REGIMM_INST: begin
				case(rtD)
					`BGEZAL,`BLTZAL: regwriteD=1'b1;
                    default: regwriteD=1'b0;
                endcase
            end
            `ADDI_SPECIAL,`ADDIU_SPECIAL,`ANDI_SPECIAL,
            `JAL_SPECIAL, `LW_SPECIAL, `LB_SPECIAL, 
            `LBU_SPECIAL, `LH_SPECIAL, `LHU_SPECIAL, 
            `LUI_SPECIAL, `SLTI_SPECIAL, `SLTIU_SPECIAL,
            `XORI_SPECIAL, `ORI_SPECIAL: regwriteD=1'b1;
            default: regwriteD=1'b0;
        endcase
    end
    
    //mem_readD
    always @(instrD) begin
        case(opD)
            `LW_SPECIAL, `LB_SPECIAL, `LBU_SPECIAL, 
            `LH_SPECIAL, `LHU_SPECIAL: mem_readD=1'b1;
            default: mem_readD=1'b0;
        endcase
    end
    
    //mem_writeD
    always @(instrD) begin
        case(opD)
            `SW_SPECIAL, `SB_SPECIAL, `SH_SPECIAL: mem_writeD=1'b1;
            default: mem_writeD=1'b0;
        endcase
    end
    
    //memtoregD
    always @(instrD) begin
        case(opD)
            `LW_SPECIAL, `LB_SPECIAL, `LBU_SPECIAL, 
            `LH_SPECIAL, `LHU_SPECIAL: memtoregD=1'b1;
            default: memtoregD=1'b0;
        endcase
    end
    
    //alucontrolD
    always @(instrD) begin
        case(opD)
            `R_SPECIAL: begin
                case(functD)
                    `ADD_FUNCT: alucontrolD=`ALU_ADD;
                    `ADDU_FUNCT: alucontrolD=`ALU_ADDU;
                    `SUB_FUNCT: alucontrolD=`ALU_SUB;
                    `SUBU_FUNCT: alucontrolD=`ALU_SUBU;
                    `SLTU_FUNCT: alucontrolD=`ALU_SLTU;
                    `SLT_FUNCT: alucontrolD=`ALU_SLT;
					`AND_FUNCT: alucontrolD=`ALU_AND;
                    `NOR_FUNCT: alucontrolD=`ALU_NOR;
                    `OR_FUNCT: alucontrolD=`ALU_OR;
                    `XOR_FUNCT: alucontrolD=`ALU_XOR;
					`SLLV_FUNCT: alucontrolD=`ALU_SLLV;
                    `SLL_FUNCT: alucontrolD=`ALU_SLL;
                    `SRAV_FUNCT: alucontrolD=`ALU_SRAV;
                    `SRA_FUNCT: alucontrolD=`ALU_SRA;
                    `SRLV_FUNCT: alucontrolD=`ALU_SRLV;
                    `SRL_FUNCT: alucontrolD=`ALU_SRL;
                    `DIV_FUNCT: alucontrolD=`ALU_DIV;
                    `DIVU_FUNCT: alucontrolD=`ALU_DIVU;
					`MULT_FUNCT: alucontrolD=`ALU_MULT;
                    `MULTU_FUNCT: alucontrolD=`ALU_MULTU;
                    `MTHI_FUNCT: alucontrolD=`ALU_MTHI;
                    `MTLO_FUNCT: alucontrolD=`ALU_MTLO;
                    default: alucontrolD=`ALU_NOP;
                endcase
            end
            `SPECIAL2: begin
                case(functD)
                    `CLO_FUNCT: alucontrolD=`ALU_CLO;
                    `CLZ_FUNCT: alucontrolD=`ALU_CLZ;
                    default: alucontrolD=`ALU_NOP;
                endcase
            end
            `COP0_SPECIAL: begin
                case(rsD)
                    `MFC0_SHAMT: alucontrolD=`ALU_MFC0;
                    default: alucontrolD=`ALU_NOP;
                endcase
            end
            `ADDI_SPECIAL, `LW_SPECIAL, `LB_SPECIAL, 
            `LBU_SPECIAL, `LH_SPECIAL, `LHU_SPECIAL,
            `SW_SPECIAL, `SB_SPECIAL, `SH_SPECIAL: alucontrolD=`ALU_ADD;

            `ADDIU_SPECIAL: alucontrolD=`ALU_ADDU;
            `ANDI_SPECIAL: alucontrolD=`ALU_AND;
            `ORI_SPECIAL: alucontrolD=`ALU_OR;
            `XORI_SPECIAL: alucontrolD=`ALU_XOR;


            `SLTI_SPECIAL: alucontrolD=`ALU_SLT;
            `SLTIU_SPECIAL: alucontrolD=`ALU_SLTU;
            `LUI_SPECIAL: alucontrolD=`ALU_LUI;

            default: alucontrolD=`ALU_NOP;
        endcase
    end
    
    //branch_judge_controlD
	always @(instrD) begin
		case(opD)
			`BEQ: branch_judge_controlD=3'b001;
			`BNE: branch_judge_controlD=3'b010;
			`BLEZ: branch_judge_controlD=3'b011;
			`BGTZ: branch_judge_controlD=3'b100;
			`REGIMM_INST: begin
				case(rtD)
					`BLTZ,`BLTZAL: branch_judge_controlD=3'b101;
					`BGEZ,`BGEZAL: branch_judge_controlD=3'b110;
					default: branch_judge_controlD=3'b101;
				endcase
				end
			default: branch_judge_controlD=3'b000;
		endcase
	end
    
endmodule