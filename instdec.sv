`include "defines2.vh"

module instdec(
    input wire [31:0] instr,
    output reg [47:0] ascii
    );

    //Instruct Divide
	wire [5:0] opD,functD;
	wire [4:0] rsD,rtD,rdD,shamtD;
	assign opD = instr[31:26];
	assign functD = instr[5:0];
	assign rsD = instr[25:21];
	assign rtD = instr[20:16];
	assign rdD = instr[15:11];
	assign shamtD = instr[10:6];

    //ALU.sv sort
    always @(*)begin
        ascii ="N-R";
        case(opD)
            //R
            `NOP:begin
                case(functD)
                    `ADD: ascii = "ADD";
                    `ADDU: ascii = "ADDU";
                    `SUB: ascii = "SUB";
                    `SUBU: ascii = "SUBU";
                    `SLTU: ascii = "SLTU";
                    `SLT: ascii = "SLT";
                    `AND: ascii = "AND";
                    `NOR: ascii = "NOR";
                    `OR: ascii = "OR";
                    `XOR: ascii = "XOR";
                    `SLLV: ascii = "SLLV";
                    `SLL: ascii = "SLL";
                    `SRAV: ascii = "SRAV";
                    `SRA: ascii = "SRA";
                    `MOVN: ascii = "MOVN";
                    `MOVZ: ascii = "MOVZ";
                    `MFHI: ascii = "MFHI";
                    `MFLO: ascii = "MFLO";
                    `SRL: ascii = "SRL";
                    `SRLV: ascii = "SRLV";
                    `JR: ascii = "JR";
                    `MULT: ascii = "MULT";
                    `MULTU: ascii = "MULTU";
                    `DIV: ascii = "DIV";
                    `DIVU: ascii = "DIVU";
                    `MTHI: ascii = "MTHI";
                    `MTLO: ascii = "MTLO";
                    `JALR: ascii = "JALR";
                    `SYSCALL: ascii = "SYSC";
                    `BREAK: ascii = "BREAK";
                    default: ascii ="N-R";
                endcase
            end
            // 算数\逻辑运算
            `ADDI: ascii = "ADDI";
            `SLTI: ascii = "SLTI";
            `SLTIU: ascii = "SLTIU";
            `ADDIU: ascii = "ADDIU";
            `ANDI: ascii = "ANDI";
            `LUI: ascii = "LUI";
            `XORI: ascii = "XORI";
            `ORI: ascii = "ORI";
            `BEQ: ascii = "BEQ";
            `BGTZ: ascii = "BGTZ";
            `BLEZ: ascii = "BLEZ";
            `BNE: ascii = "BNE";
            `REGIMM_INST: begin
				case(rtD)
                    `BLTZ: ascii = "BLTZ";
                    `BGEZ: ascii = "BGEZ";
                    `BLTZAL: ascii = "BLTZAL";
                    `BGEZAL: ascii = "BGEZAL";
                    default: ascii = "N-R";
                endcase
            end
            // 访存指令，都是立即数指令
            `LW: ascii = "LW";
            `LB: ascii = "LB";
            `LBU: ascii = "LBU";
            `LH: ascii = "LH";
            `LHU: ascii = "LHU";
            `LWL: ascii = "LWL";
            `LWR: ascii = "LWR";
            `LL: ascii = "LL";
            `SW: ascii = "SW";
            `SB: ascii = "SB";
            `SH: ascii = "SH";
            `SWL: ascii = "SWL";
            `SWR: ascii = "SWR";
            //  J type
            `J: ascii = "J";
            `JAL: ascii = "JAL";
            
            `COP0_INST:begin
				case(rsD)
                    `MFC0: ascii = "MFC0";
                    `MTC0: ascii = "MTC0";
                    default: ascii = "N-R";
                endcase
			end
            `SPECIAL2_INST: begin
				case(functD)
                    `CLO: ascii = "CLO";
                    `CLZ: ascii = "CLZ";
                    `MUL: ascii = "MUL";
                    `MADD: ascii = "MADD";
                    `MADDU: ascii = "MADDU";
                    `MSUB: ascii = "MSUB";
                    `MSUBU: ascii = "MSUBU";
                    default: ascii = "N-R";
                endcase
			end
            `SPECIAL3_INST: begin
				case(functD)
                    `BSHFL: begin
                        case(shamtD)
                            `SEB: ascii = "SEB";
                            `SEH: ascii = "SEH";
                            `WSBH: ascii = "WSBH";
                            default: ascii = "N-R";
                        endcase
                    end
                    `EXT: ascii = "EXT";
                    `INS: ascii = "INS";
                    default: ascii = "N-R";
                endcase
			end
            default: ascii = "N-R";
        endcase
        if(instr==`RS_CO)
            ascii = "RS_CO";
        if(!instr)
            ascii = "NOP";
    end
endmodule

