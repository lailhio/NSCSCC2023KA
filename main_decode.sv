// ALU OP 8bit
`define ALU_NOP 8'b00000000
`define ALU_ADD 8'b00000001
`define ALU_ADDU 8'b00000010
`define ALU_AND 8'b00000011
`define ALU_CLO 8'b00000100
`define ALU_CLZ 8'b00000101
`define ALU_DIV 8'b00000110
`define ALU_DIVU 8'b00000111

// Basic
`define R_SPECIAL 6'b000000

// Integer instructions

// ADD
`define ADD_SPECIAL 6'b000000
`define ADD_FUNCT 6'b100000

//ADDI
`define ADDI_SPECIAL 6'b001000

//ADDIU
`define ADDIU_SPECIAL 6'b001001

//ADDU
`define ADDU_SPECIAL 6'b000000
`define ADDU_FUNCT 6'b100001

//AND
`define AND_SPECIAL 6'b000000
`define AND_FUNCT 6'b100100

//ANDI
`define ANDI_SPECIAL 6'b001100

//BEQ
`define BEQ_SPECIAL 6'b000100

//BGEZ
`define BGEZ_SPECIAL 6'b000001
`define BGEZ_SHAMT 5'b00001

//BGEZAL or BAL
`define BGEZAL_SPECIAL 6'b000001
`define BGEZAL_SHAMT 5'b10001

//BGTZ
`define BGTZ_SPECIAL 6'b000111

//BLEZ
`define BLEZ_SPECIAL 6'b000110

//BLTZ
`define BLTZ_SPECIAL 6'b000001

//BLTZAL
`define BLTZAL_SPECIAL 6'b000001
`define BLTZAL_SHAMT 5'b10000

//BNE
`define BNE_SPECIAL 6'b000101

//BREAK
`define BREAK_F 6'b001101

//CACHE                    ???
`define CACHE_SPECIAL 6'b101111

//CLO
`define CLO_SPECIAL 6'b011100
`define CLO_FUNCT 6'b100001

//CLZ
`define CLZ_SPECIAL 6'b011100
`define CLZ_FUNCT 6'b100000

//DIV
`define DIV_SPECIAL 6'b000000
`define DIV_FUNCT 6'b011010

//DIVU
`define DIVU_SPECIAL 6'b000000
`define DIVU_FUNCT 6'b011011

//EXT   2?
`define EXT_SPECIAL 6'b011111
`define EXT_FUNCT 6'b000000

//INS   2?
`define INS_SPECIAL 6'b011111
`define INS_FUNCT 6'b000100

//J
`define J_SPECIAL 6'b000010

//JAL
`define JAL_SPECIAL 6'b000011

//JALR
`define JALR_SPECIAL 6'b000000
`define JALR_FUNCT 6'b001001

//JR
`define JR_SPECIAL 6'b000000
`define JR_FUNCT 6'b001000

//LB
`define LB_SPECIAL 6'b100000

//LBU
`define LBU_SPECIAL 6'b100100

//LH
`define LH_SPECIAL 6'b100001

//LHU
`define LHU_SPECIAL 6'b100101

//LL
`define LL_SPECIAL 6'b110000

//LUI
`define LUI_SPECIAL 6'b001111

//LW
`define LW_SPECIAL 6'b100011

//LWL
`define LWL_SPECIAL 6'b100010

//LWR
`define LWR_SPECIAL 6'b100110

//MADD
`define MADD_SPECIAL 6'b011100
`define MADD_FUNCT 6'b000000

//MADDU
`define MADDU_SPECIAL 6'b011100
`define MADDU_FUNCT 6'b000001

//MFHI
`define MFHI_SPECIAL 6'b000000
`define MFHI_FUNCT 6'b010000

//MFLO
`define MFLO_SPECIAL 6'b000000
`define MFLO_FUNCT 6'b010010

//MOVN
`define MOVN_SPECIAL 6'b000000
`define MOVN_FUNCT 6'b001011

//MOVZ
`define MOVZ_SPECIAL 6'b000000
`define MOVZ_FUNCT 6'b001010

//MSUB
`define MSUB_SPECIAL 6'b011100
`define MSUB_FUNCT 6'b000100

//MSUBU
`define MSUBU_SPECIAL 6'b011100
`define MSUBU_FUNCT 6'b000101

//MTHI
`define MTHI_SPECIAL 6'b000000
`define MTHI_FUNCT 6'b010001

//MTLO
`define MTLO_SPECIAL 6'b000000
`define MTLO_FUNCT 6'b010011

//MUL
`define MUL_SPECIAL 6'b011100
`define MUL_FUNCT 6'b000010

//MULT
`define MULT_SPECIAL 6'b000000
`define MULT_FUNCT 6'b011000

//MULTU
`define MULTU_SPECIAL 6'b000000
`define MULTU_FUNCT 6'b011001

//NOP
`define NOP_SPECIAL 6'b000000
`define NOP_FUNCT 6'b000000

//NOR
`define NOR_SPECIAL 6'b000000
`define NOR_FUNCT 6'b100111

//OR
`define OR_SPECIAL 6'b000000
`define OR_FUNCT 6'b100101

//ORI
`define ORI_SPECIAL 6'b001101

//PAUSE
`define PAUSE_SPECIAL 6'b000000
`define PAUSE_SHAMT 5'b00101
`define PAUSE_FUNCT 6'b000000

//PREF
`define PREF_SPECIAL 6'b110011

//RDHWR
`define RDHWR_SPECIAL 6'b011111
`define RDHWR_FUNCT 6'b111011

//ROTR   2?
`define ROTR_SPECIAL 6'b000000
`define ROTR_FUNCT 6'b000010

//ROTRV  2?
`define ROTRV_SPECIAL 6'b000000
`define ROTRV_FUNCT 6'b000110

//SB
`define SB_SPECIAL 6'b101000

//SC
`define SC_SPECIAL 6'b111000

//SEB     2?
`define SEB_SPECIAL 6'b011111
`define SEB_SHAMT 5'b10000
`define SEB_FUNCT 6'b100000

//SEH   2?
`define SEH_SPECIAL 6'b011111
`define SEH_SHAMT 5'b11000
`define SEH_FUNCT 6'b100000

//SH
`define SH_SPECIAL 6'b101001

//SLL
`define SLL_SPECIAL 6'b000000
`define SLL_FUNCT 6'b000000

//SLLV
`define SLLV_SPECIAL 6'b000000
`define SLLV_FUNCT 6'b000100

//SLT
`define SLT_SPECIAL 6'b000000
`define SLT_FUNCT 6'b101010

//SLTI
`define SLTI_SPECIAL 6'b001010

//SLTIU
`define SLTIU_SPECIAL 6'b001011

//SLTU
`define SLTU_SPECIAL 6'b000000
`define SLTU_FUNCT 6'b101011

//SRA
`define SRA_SPECIAL 6'b000000
`define SRA_FUNCT 6'b000011

//SRAV
`define SRAV_SPECIAL 6'b000000
`define SRAV_FUNCT 6'b000111

//SRL
`define SRL_SPECIAL 6'b000000
`define SRL_FUNCT 6'b000010

//SRLV
`define SRLV_SPECIAL 6'b000000
`define SRLV_FUNCT 6'b000110

//SSNOP
`define SSNOP_SPECIAL 6'b000000
`define SSNOP_FUNCT 6'b000000

//SUB
`define SUB_SPECIAL 6'b000000
`define SUB_FUNCT 6'b100010

//SUBU
`define SUBU_SPECIAL 6'b000000
`define SUBU_FUNCT 6'b100011

//SW
`define SW_SPECIAL 6'b101011

//SWL
`define SWL_SPECIAL 6'b101010

//SWR
`define SWR_SPECIAL 6'b101110

//SYNC
`define SYNC_SPECIAL 6'b000000
`define SYNC_FUNCT 6'b001111

//SYNCI
`define SYNCI_SPECIAL 6'b000001
`define SYNCI_RT 5'b11111

//SYSCALL
`define SYSCALL_SPECIAL 6'b000000
`define SYSCALL_FUNCT 6'b001100

//TEQ
`define TEQ_SPECIAL 6'b000000
`define TEQ_FUNCT 6'b110100

//TEQI
`define TEQI_SPECIAL 6'b000001
`define TEQI_RT 5'b01100

//TGE
`define TGE_SPECIAL 6'b000000
`define TGE_FUNCT 6'b110000

//TGEI
`define TGEI_SPECIAL 6'b000001
`define TGEI_RT 5'b01000

//TGEIU
`define TGEIU_SPECIAL 6'b000001
`define TGEIU_RT 5'b01001

//TGEU
`define TGEU_SPECIAL 6'b000000
`define TGEU_FUNCT 6'b110001

//TLBP
`define TLBP_SPECIAL 6'b010000
`define TLBP_FUNCT 6'b001000

//TLBR
`define TLBR_SPECIAL 6'b010000
`define TLBR_FUNCT 6'b000001

//TLBWI
`define TLBWI_SPECIAL 6'b010000
`define TLBWI_FUNCT 6'b000010

//TLBWR
`define TLBWR_SPECIAL 6'b010000
`define TLBWR_FUNCT 6'b000110

//TLT
`define TLT_SPECIAL 6'b000000
`define TLT_FUNCT 6'b110010

//TLTI
`define TLTI_SPECIAL 6'b000001
`define TLTI_RT 5'b01010

//TLTIU
`define TLTIU_SPECIAL 6'b000001
`define TLTIU_RT 5'b01011

//TLTU
`define TLTU_SPECIAL 6'b000000
`define TLTU_FUNCT 6'b110011

//TNE
`define TNE_SPECIAL 6'b000000
`define TNE_FUNCT 6'b110110

//TNEI
`define TNEI_SPECIAL 6'b000001
`define TNEI_RT 5'b01110

//WSBH        2?
`define WSBH_SPECIAL 6'b011111
`define WSBH_SHAMT 5'b00010
`define WSBH_FUNCT 6'b100000

//XOR
`define XOR_SPECIAL 6'b000000
`define XOR_FUNCT 6'b100110

//XORI
`define XORI_SPECIAL 6'b001110


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
		output reg [7:0] aluopD,
		// output reg [5:0] funct_to_aluD,
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
	
	assign breakD = ~(|(opD ^ `R_SPECIAL)) & ~(|(functD ^ `BREAK));
	assign syscallD = ~(|(opD ^ `R_SPECIAL)) & ~(|(functD ^ `SYSCALL));
    
    //riD
    always @(*) begin
        case(opD)

            default: riD=1'b0;
        endcase
    end
    
    //is_mfcD
    always @(*) begin
        case(opD)

            default: is_mfcD=1'b0;
        endcase
    end
    
    //regdstD
    always @(*) begin
        case(opD)
            `R_SPECIAL:begin
                case(functD)
                    `JALR_SPECIAL: regdstD=2'b10;
                    default: regdstD=2'b00;
                endcase
            end
            `ADDI_SPECIAL,`ADDIU_SPECIAL,`ANDI_SPECIAL: regdstD=2'b01;
            default: regdstD=2'b00;
        endcase
    end
    
    //is_immD
    always @(*) begin
        case(opD)
            `ADDI_SPECIAL,`ADDIU_SPECIAL,`ANDI_SPECIAL: is_immD=1'b1;
            default: is_immD=1'b0;
        endcase
    end
    
    //regwriteD
    always @(*) begin
        case(opD)
            `R_SPECIAL: begin
                case(functD)
                    `JR_SPECIAL: regwriteD=1'b0;
                    default: regwriteD=1'b1;
                endcase
            end
            `ADDI_SPECIAL,`ADDIU_SPECIAL,`ANDI_SPECIAL: regwriteD=1'b1;
            default: regwriteD=1'b0;
        endcase
    end
    
    //mem_readD
    always @(*) begin
        case(opD)
            default: mem_readD=1'b0;
        endcase
    end
    
    //mem_writeD
    always @(*) begin
        case(opD)
            default: mem_writeD=1'b0;
        endcase
    end
    
    //memtoregD
    always @(*) begin
        case(opD)
            default: memtoregD=1'b0;
        endcase
    end
    
    //aluopD
    always @(*) begin
        case(opD)
            `R_SPECIAL: begin
                case(functD)
                    `ADD_FUNCT: aluopD=`ALU_ADD;
                    `ADDU_FUNCT: aluopD=`ALU_ADDU;
                    `AND_FUNCT: aluopD=`ALU_AND;
                    default: aluopD=`ALU_NOP;
                endcase
            end
            `ADDI_SPECIAL: aluopD=`ALU_ADD;
            `ADDIU_SPECIAL: aluopD=`ALU_ADDU;
            `ANDI_SPECIAL: aluopD=`ALU_AND;
            default: aluopD=`ALU_NOP;
        endcase
    end
    
    //branch_judge_controlD
	always @(*) begin
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