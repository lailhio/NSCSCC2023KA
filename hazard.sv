`timescale 1ns / 1ps


module hazard(
    input wire i_cache_stall,
	input wire d_cache_stall,
    input wire alu_stallE, 
    input wire master_only_oneD, slave_only_oneD,
    input wire master_mem_conflitD, slave_mem_conflitD,

    input wire pred_failed_masterE, pred_failed_slaveE, flush_exception_masterE, flush_exception_slaveE,
    input wire jump1D, jump2D, pred_take1D, pred_take2D, Blank1_SL, Blank2_SL, 

    input ctrl_sign dec_sign1D, dec_sign2D, dec_sign1E, dec_sign2E, 
    input ctrl_sign dec_sign1M, dec_sign2M, dec_sign1W, dec_sign2W, 

    input wire [4:0] rs1D, rs2D,// operand
    input wire [4:0] rt1D, rt2D,
    
    output wire stallF, stallF2, stall_masterD, stall_slaveD, stall_masterE, stall_slaveE, stall_masterM, stall_slaveM, 
    output wire stall_masterW, stall_slaveW, 
    output wire flushF, flushF2, flush_masterD, flush_masterE, flush_masterM, flush_masterW,
    output wire flush_slaveD, flush_slaveE, flush_slaveM, flush_slaveW,
    output wire stallDblank, icache_Ctl, fulsh_ex, dcache_ctl,

    output wire [2:0] forward1_1D, forward1_2D, forward2_1D, forward2_2D
);
    
    wire id_cache_stall, longest_stall;
    //  1、 if Ex、Mem or Wb is same
    //  2、 And if ExInst is lw or Mfhilo
    //  ps : lw des rt, mfc0 des rt, mfhilo des rd
    assign forward1_1D = (|(rs1D ^ 0)) & dec_sign2E.regwrite & (~|(rs1D ^ dec_sign2E.writereg)) ? 3'b110 :
                        (|(rs1D ^ 0)) & dec_sign1E.regwrite & (~|(rs1D ^ dec_sign1E.writereg)) ? 3'b101 :
                        (|(rs1D ^ 0)) & dec_sign2M.regwrite & (~|(rs1D ^ dec_sign2M.writereg)) ? 3'b100 :
                        (|(rs1D ^ 0)) & dec_sign1M.regwrite & (~|(rs1D ^ dec_sign1M.writereg)) ? 3'b011 :
                        (|(rs1D ^ 0)) & dec_sign2W.regwrite & (~|(rs1D ^ dec_sign2W.writereg)) ? 3'b010 :
                        (|(rs1D ^ 0)) & dec_sign1W.regwrite & (~|(rs1D ^ dec_sign1W.writereg)) ? 3'b001 :
                        3'b000;
    assign forward1_2D = (|(rt1D ^ 0)) & dec_sign2E.regwrite & (~|(rt1D ^ dec_sign2E.writereg)) ? 3'b110 :
                        (|(rt1D ^ 0)) & dec_sign1E.regwrite & (~|(rt1D ^ dec_sign1E.writereg)) ? 3'b101 :
                        (|(rt1D ^ 0)) & dec_sign2M.regwrite & (~|(rt1D ^ dec_sign2M.writereg)) ? 3'b100 :
                        (|(rt1D ^ 0)) & dec_sign1M.regwrite & (~|(rt1D ^ dec_sign1M.writereg)) ? 3'b011 :
                        (|(rt1D ^ 0)) & dec_sign2W.regwrite & (~|(rt1D ^ dec_sign2W.writereg)) ? 3'b010 :
                        (|(rt1D ^ 0)) & dec_sign1W.regwrite & (~|(rt1D ^ dec_sign1W.writereg)) ? 3'b001 :
                        3'b000;
    assign forward2_1D = (|(rs2D ^ 0)) & dec_sign2E.regwrite & (~|(rs2D ^ dec_sign2E.writereg)) ? 3'b110 :
                        (|(rs2D ^ 0)) & dec_sign1E.regwrite & (~|(rs2D ^ dec_sign1E.writereg)) ? 3'b101 :
                        (|(rs2D ^ 0)) & dec_sign2M.regwrite & (~|(rs2D ^ dec_sign2M.writereg)) ? 3'b100 :
                        (|(rs2D ^ 0)) & dec_sign1M.regwrite & (~|(rs2D ^ dec_sign1M.writereg)) ? 3'b011 :
                        (|(rs2D ^ 0)) & dec_sign2W.regwrite & (~|(rs2D ^ dec_sign2W.writereg)) ? 3'b010 :
                        (|(rs2D ^ 0)) & dec_sign1W.regwrite & (~|(rs2D ^ dec_sign1W.writereg)) ? 3'b001 :
                        3'b000;
    assign forward2_2D = (|(rt2D ^ 0)) & dec_sign2E.regwrite & (~|(rt2D ^ dec_sign2E.writereg)) ? 3'b110 :
                        (|(rt2D ^ 0)) & dec_sign1E.regwrite & (~|(rt2D ^ dec_sign1E.writereg)) ? 3'b101 :
                        (|(rt2D ^ 0)) & dec_sign2M.regwrite & (~|(rt2D ^ dec_sign2M.writereg)) ? 3'b100 :
                        (|(rt2D ^ 0)) & dec_sign1M.regwrite & (~|(rt2D ^ dec_sign1M.writereg)) ? 3'b011 :
                        (|(rt2D ^ 0)) & dec_sign2W.regwrite & (~|(rt2D ^ dec_sign2W.writereg)) ? 3'b010 :
                        (|(rt2D ^ 0)) & dec_sign1W.regwrite & (~|(rt2D ^ dec_sign1W.writereg)) ? 3'b001 :
                        3'b000;
    assign id_cache_stall=d_cache_stall|i_cache_stall;

    wire branch1_ok = pred_take1D;
    wire pc_change1D = (jump1D | branch1_ok);
    wire branch2_ok = pred_take2D;
    wire pc_change2D = (jump2D | branch2_ok);

    assign fulsh_ex = flush_exception_masterE | flush_exception_slaveE;
    wire only_one = master_only_oneD | slave_only_oneD  | (master_mem_conflitD & slave_mem_conflitD) 
                | (dec_sign1D.regwrite 
                & (dec_sign2D.read_rs & rs2D == dec_sign1D.writereg 
                |  dec_sign2D.read_rt & rt2D == dec_sign1D.writereg));
    wire pred_failed = pred_failed_masterE | pred_failed_slaveE;
    
    assign longest_stall=id_cache_stall | alu_stallE;

    // Is mfc0 mfhilo lw and Operand is the same 
    assign stallDblank= ((forward1_1D == 3'b110 | forward1_1D == 3'b101 | forward1_2D == 3'b110 | forward1_2D == 3'b101) & (dec_sign1E.mem_read  | dec_sign2E.mem_read))
                        |((forward2_1D == 3'b110 | forward2_1D == 3'b101 | forward2_2D == 3'b110 | forward2_2D == 3'b101) & (dec_sign1E.mem_read | dec_sign2E.mem_read));

    assign stallF = ~(fulsh_ex | pred_failed | pc_change1D | pc_change2D) & (id_cache_stall | alu_stallE | stallDblank  | only_one | Blank1_SL | Blank2_SL);
    assign icache_Ctl = d_cache_stall | alu_stallE| stallDblank  | only_one | Blank1_SL | Blank2_SL ;
    assign dcache_ctl =  ~flush_exception_slaveE & (i_cache_stall| alu_stallE);
    assign stallF2 =  id_cache_stall | alu_stallE| stallDblank  | only_one | Blank1_SL | Blank2_SL;

    assign stall_masterD =  id_cache_stall| alu_stallE | stallDblank | Blank1_SL | Blank2_SL;
    assign stall_slaveD = id_cache_stall| alu_stallE | stallDblank  | only_one | Blank1_SL | Blank2_SL;

    assign stall_masterE =  id_cache_stall| alu_stallE | Blank1_SL | Blank2_SL;
    assign stall_slaveE =  id_cache_stall| alu_stallE | Blank1_SL | Blank2_SL;

    assign stall_masterM =   ~flush_exception_slaveE & (id_cache_stall| alu_stallE);
    assign stall_slaveM =  id_cache_stall| alu_stallE;
    
    assign stall_masterW = ~fulsh_ex & (id_cache_stall| alu_stallE);
    assign stall_slaveW =  ~fulsh_ex & (id_cache_stall| alu_stallE);

    assign flushF = 1'b0;

    assign flushF2 = fulsh_ex | pred_failed | pc_change1D | (pc_change2D & ~stallF2); 

    assign flush_masterD = fulsh_ex | pred_failed_masterE | ((pc_change1D | pred_failed_slaveE |  only_one) & ~stall_masterD);
    assign flush_slaveD = fulsh_ex | pred_failed  | ((pc_change1D | pc_change2D) & ~stall_slaveD);

    assign flush_masterE = fulsh_ex | ((pred_failed_masterE |stallDblank) & ~stall_masterE);
    assign flush_slaveE = fulsh_ex  | (((pred_failed_masterE & dec_sign2E.delayslot) | pred_failed_slaveE | stallDblank | only_one) & ~stall_slaveE) ;

    assign flush_masterM = flush_exception_masterE | ((Blank1_SL | Blank2_SL & ~flush_exception_slaveE) & ~stall_masterM);
    assign flush_slaveM = fulsh_ex| ((Blank1_SL | Blank2_SL) & ~stall_slaveM);

    
    assign flush_masterW = 1'b0;
    assign flush_slaveW = 1'b0;
endmodule
