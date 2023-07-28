`ifndef DEF_COMMON
`define DEF_COMMON

// ALU OP 8bit
`define ALU_NOP 8'b00000000
`define ALU_ADD 8'b00000001
`define ALU_ADDU 8'b00000010
`define ALU_SUB 8'b00000011
`define ALU_SUBU 8'b00000100
`define ALU_AND 8'b00000101
`define ALU_OR 8'b00000110
`define ALU_XOR 8'b00000111
`define ALU_NOR 8'b00001000
`define ALU_SLT 8'b00001001
`define ALU_SLTU 8'b00001010
`define ALU_SLL 8'b00001011
`define ALU_SRL 8'b00001100
`define ALU_SRA 8'b00001101
`define ALU_SLLV 8'b00001110
`define ALU_SRLV 8'b00001111
`define ALU_SRAV 8'b00010000
`define ALU_LUI 8'b00010001
`define ALU_MTHI 8'b00010010
`define ALU_MTLO 8'b00010011
`define ALU_MULT 8'b00010100
`define ALU_MULTU 8'b00010101
`define ALU_DIV 8'b00010110
`define ALU_DIVU 8'b00010111
`define ALU_CLO 8'b00011000
`define ALU_CLZ 8'b00011001
`define ALU_MFC0 8'b00011010
`define ALU_MTC0 8'b00011011
`define ALU_MFHI 8'b00011100
`define ALU_MFLO 8'b00011101
`define ALU_SEB 8'b00011110
`define ALU_SEH 8'b00011111



// Basic
`define R_SPECIAL 6'b000000
`define REGIMM_SPRCIAL 6'b000001
`define SPECIAL2 6'b011100
`define COP0_SPECIAL 6'b010000

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
`define BLTZ_SHAMT 5'b00000

//BLTZAL
`define BLTZAL_SPECIAL 6'b000001
`define BLTZAL_SHAMT 5'b10000

//BNE
`define BNE_SPECIAL 6'b000101

//BREAK
`define BREAK_FUNCT 6'b001101

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

//MTC0
`define MTC0_SHAMT 5'b00100

//MFC0
`define MFC0_SHAMT 5'b00000

// global macro definition
`define RstEnable 		1'b1
`define RstDisable		1'b0
`define ZeroWord		32'h00000000
`define WriteEnable		1'b1
`define WriteDisable	1'b0
`define ReadEnable		1'b1
`define ReadDisable		1'b0
`define AluOpBus		7:0
`define AluSelBus		2:0
`define InstValid		1'b0
`define InstInvalid		1'b1
`define Stop 			1'b1
`define NoStop 			1'b0
`define InDelaySlot 	1'b1
`define NotInDelaySlot 	1'b0
`define Branch 			1'b1
`define NotBranch 		1'b0
`define InterruptAssert 1'b1
`define InterruptNotAssert 1'b0
`define TrapAssert 		1'b1
`define TrapNotAssert 	1'b0
`define True_v			1'b1
`define False_v			1'b0
`define ChipEnable		1'b1
`define ChipDisable		1'b0
`define AHB_IDLE 2'b00
`define AHB_BUSY 2'b01
`define AHB_WAIT_FOR_STALL 2'b11

//specific inst macro definition

`define NOP			6'b000000
`define AND 		6'b100100
`define OR 			6'b100101
`define XOR 		6'b100110
`define NOR			6'b100111
`define ANDI		6'b001100
`define ORI			6'b001101
`define XORI		6'b001110
`define LUI			6'b001111

`define SLL			6'b000000
`define SLLV		6'b000100
`define SRL 		6'b000010
`define SRLV 		6'b000110
`define SRA 		6'b000011
`define SRAV 		6'b000111

`define MFHI  		6'b010000
`define MTHI  		6'b010001  
`define MFLO  		6'b010010
`define MTLO  		6'b010011

`define SLT  6'b101010
`define SLTU  6'b101011
`define SLTI  6'b001010
`define SLTIU  6'b001011   
`define ADD  6'b100000
`define ADDU  6'b100001
`define SUB  6'b100010
`define SUBU  6'b100011
`define ADDI  6'b001000
`define ADDIU  6'b001001

`define MULT  6'b011000
`define MULTU  6'b011001
`define DIV  6'b011010
`define DIVU  6'b011011

`define J  6'b000010
`define JAL  6'b000011
`define JALR  6'b001001
`define JR  6'b001000
`define BEQ  6'b000100
`define BGEZ  5'b00001
`define BGEZAL  5'b10001
`define BGTZ  6'b000111
`define BLEZ  6'b000110
`define BLTZ  5'b00000
`define BLTZAL  5'b10000
`define BNE  6'b000101

`define LB  6'b100000
`define LBU  6'b100100
`define LH  6'b100001
`define LHU  6'b100101
`define LW  6'b100011
`define SB  6'b101000
`define SH  6'b101001
`define SW  6'b101011

`define SYSCALL 6'b001100
`define BREAK 6'b001101
   
`define ERET 5'b10000

`define R_TYPE 6'b000000
`define REGIMM_INST 6'b000001
// `define SPECIAL3_INST 6'b010000
`define COP0_INST 6'b010000
//change the SPECIAL2_INST from 6'b011100 to 6'b010000
`define MTC0 5'b00100
`define MFC0 5'b00000


`define SPECIAL2_INST 6'b011100
`define SPECIAL3_INST 6'b011111

`define CLO 6'b100001
`define CLZ 6'b100000

`define SEB 5'b10000
`define SEH 5'b11000 

`define BSHFL 6'b100000
`define EXT 6'b000000
`define INS 6'b000100

`define WSBH 5'b00010

`define MOVN 6'b001011
`define MOVZ 6'b001010

`define MADD    6'b000000 
`define MADDU   6'b000001
`define MSUB    6'b000100
`define MSUBU   6'b000101
`define MUL     6'b000010

`define LWL     6'b100010
`define LWR     6'b100110
`define SWL     6'b101010
`define SWR     6'b101110

// ALU OP 4bit

// `define ANDI_OP 4'b0000
// `define XORI_OP 4'b0001
// `define ORI_OP  4'b0010
// `define LUI_OP  4'b0011
// `define ADDI_OP 4'b0100
// `define ADDIU_OP    4'b0101
// `define SLTI_OP     4'b0110
// `define SLTIU_OP    4'b0111

// `define MEM_OP  4'b0100


// `define R_TYPE_OP 4'b1000
// `define MFC0_OP 4'b1001
// `define MTC0_OP 4'b1010
// `define USELESS_OP 4'b1111

// ALU OP 6bit

`define ANDI_OP     6'b000000
`define XORI_OP     6'b000001
`define ORI_OP      6'b000010
`define LUI_OP      6'b000011
`define ADDI_OP     6'b000100
`define ADDIU_OP    6'b000101
`define SLTI_OP     6'b000110
`define SLTIU_OP    6'b000111

`define MEM_OP      6'b000100


`define R_TYPE_OP   6'b001000
`define MFC0_OP     6'b001001
`define MTC0_OP     6'b001010
`define USELESS_OP  6'b111111

`define CLO_OP      6'b001011
`define CLZ_OP      6'b001100

`define SEB_OP      6'b001101
`define SEH_OP      6'b001110

`define ROTR_OP     6'b001111
`define ROTRV_OP    6'b010000

`define EXT_OP      6'b010001
`define INS_OP      6'b010010

`define WSBH_OP     6'b010011

`define MOVN_OP     6'b010100
`define MOVZ_OP     6'b010101

`define MADD_OP     6'b010110
`define MADDU_OP    6'b010111
`define MSUB_OP     6'b011000
`define MSUBU_OP    6'b011001
`define MUL_OP      6'b011010

// // ALU CONTROL 5bit
// `define AND_CONTROL 5'b00111
// `define OR_CONTROL  5'b00001
// `define XOR_CONTROL 5'b00010
// `define NOR_CONTROL 5'b00011
// `define LUI_CONTROL 5'b00100

// `define SLL_CONTROL 5'b01000
// `define SRL_CONTROL 5'b01001
// `define SRA_CONTROL 5'b01010
// `define SLLV_CONTROL    5'b01011
// `define SRLV_CONTROL    5'b01100
// `define SRAV_CONTROL    5'b01101

// `define ADD_CONTROL     5'b10000
// `define ADDU_CONTROL    5'b10001
// `define SUB_CONTROL     5'b10010
// `define SUBU_CONTROL    5'b10011
// `define SLT_CONTROL     5'b10100
// `define SLTU_CONTROL    5'b10101

// `define MULT_CONTROL    5'b11000
// `define MULTU_CONTROL   5'b11001
// `define DIV_CONTROL     5'b11010
// `define DIVU_CONTROL    5'b11011

// `define MFHI_CONTROL  	5'b11100
// `define MTHI_CONTROL  	5'b11101
// `define MFLO_CONTROL  	5'b11110
// `define MTLO_CONTROL  	5'b11111

// `define MFC0_CONTROL 	5'b00101
// `define MTC0_CONTROL 	5'b00110

// ALU CONTROL 8bit

`define AND_CONTROL     8'b00000001
`define OR_CONTROL      8'b00000010
`define XOR_CONTROL     8'b00000011
`define NOR_CONTROL     8'b00000100
`define LUI_CONTROL     8'b00000101

`define SLL_CONTROL     8'b00000110
`define SRL_CONTROL     8'b00000111
`define SRA_CONTROL     8'b00001000
`define SLLV_CONTROL    8'b00001001
`define SRLV_CONTROL    8'b00001010
`define SRAV_CONTROL    8'b00001011

`define ADD_CONTROL     8'b00001100
`define ADDU_CONTROL    8'b00001101
`define SUB_CONTROL     8'b00001110
`define SUBU_CONTROL    8'b00001111
`define SLT_CONTROL     8'b00010000
`define SLTU_CONTROL    8'b00010001

`define MULT_CONTROL    8'b00010010
`define MULTU_CONTROL   8'b00010011
`define DIV_CONTROL     8'b00010100
`define DIVU_CONTROL    8'b00010101

`define MFHI_CONTROL  	8'b00010110
`define MTHI_CONTROL  	8'b00010111
`define MFLO_CONTROL  	8'b00011000
`define MTLO_CONTROL  	8'b00011001

`define MFC0_CONTROL 	8'b00011010
`define MTC0_CONTROL    8'b00011011

`define CLO_CONTROL     8'b00011100
`define CLZ_CONTROL     8'b00011101

`define SEB_CONTROL     8'b00011110
`define SEH_CONTROL     8'b00011111

`define ROTR_CONTROL    8'b00100000
`define ROTRV_CONTROL   8'b00100001

`define EXT_CONTROL     8'b00100010
`define INS_CONTROL     8'b00100011

`define WSBH_CONTROL    8'b00100100

`define MOVN_CONTROL    8'b00100101
`define MOVZ_CONTROL    8'b00100110

`define MADD_CONTROL    8'b00100111
`define MADDU_CONTROL   8'b00101000
`define MSUB_CONTROL    8'b00101001
`define MSUBU_CONTROL   8'b00101010
`define MUL_CONTROL     8'b00101011

//inst ROM macro definition
`define InstAddrBus		31:0
`define InstBus 		31:0

//data RAM
`define DataAddrBus 31:0
`define DataBus 31:0
`define ByteWidth 7:0

//regfiles macro definition

`define RegAddrBus		4:0
`define RegBus 			31:0
`define RegWidth		32
`define DoubleRegWidth	64
`define DoubleRegBus	63:0
`define RegNum			32
`define RegNumLog2		5
`define NOPRegAddr		5'b00000

//div
`define DivFree 2'b00
`define DivByZero 2'b01
`define DivOn 2'b10
`define DivEnd 2'b11
`define DivResultReady 1'b1
`define DivResultNotReady 1'b0
`define DivStart 1'b1
`define DivStop 1'b0

//CP0
`define CP0_REG_BADVADDR    5'b01000       
`define CP0_REG_COUNT    5'b01001        
`define CP0_REG_COMPARE    5'b01011      
`define CP0_REG_STATUS    5'b01100       
`define CP0_REG_CAUSE    5'b01101       
`define CP0_REG_EPC    5'b01110          
`define CP0_REG_PRID    5'b01111         
`define CP0_REG_CONFIG    5'b10000      

// tlb 
//TLB Config
`define TLB_LINE_NUM 8
`define TAG_WIDTH 20
`define OFFSET_WIDTH 12
`define LOG2_TLB_LINE_NUM 5

typedef struct packed {
    logic        G;
    logic        V0;
    logic        V1;
    logic        D0;
    logic        D1;
    logic        C0;    // 1 as cacheable
    logic        C1;    // 1 as cacheable
    logic [19:0] PFN0;
    logic [19:0] PFN1;
    logic [18:0] VPN2;
    logic  [7:0] ASID;
} tlb_entry;

typedef struct packed {
    logic       refill;
    logic       invalid;
    logic [31:0]addr;
    logic [31:0]data;
} fifo_entry;

typedef struct packed {
    logic [5:0] F; // for 32 bit PALEN, F is 6 bit.
    logic [19:0]PFN;
    logic [2:0] C;
    logic       D;
    logic       V;
    logic       G;
} cp0_entrylo;

`endif