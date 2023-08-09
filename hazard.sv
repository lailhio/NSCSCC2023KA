`timescale 1ns / 1ps


module hazard(
    input wire i_cache_stall,
	input wire d_cache_stall,
    input wire alu_stallE, 
    input wire master_only_oneD, slave_only_oneD,

    input wire pred_failed_masterE, pred_failed_slaveE, flush_exception_masterM, flush_exception_slaveM,
    input wire jump1D, jump2D, pred_take1D, pred_take2D,

    input ctrl_sign dec_sign1D, dec_sign2D, dec_sign1E, dec_sign2E, 
    input ctrl_sign dec_sign1M, dec_sign2M, dec_sign1M2, dec_sign2M2, dec_sign1W, dec_sign2W, 

    input wire [4:0] rs1D, rs2D,// operand
    input wire [4:0] rt1D, rt2D,
    
    output wire stallF, stallF2, stall_masterD, stall_slaveD, stall_masterE, stall_slaveE, stall_masterM, stall_slaveM, 
    output wire stall_masterM2, stall_slaveM2, stall_masterW, stall_slaveW, 
    output wire flushF, flushF2, flush_masterD, flush_masterE, flush_masterM, flush_masterM2, flushW,
    output wire flush_slaveD, flush_slaveE, flush_slaveM, flush_slaveM2,
    output wire stallDblank, icache_Ctl, fulsh_ex, 

    output wire [3:0] forward1_1D, forward1_2D, forward2_1D, forward2_2D
);
    
    wire id_cache_stall, longest_stall;
    //  1、 if Ex、Mem or Wb is same
    //  2、 And if ExInst is lw or Mfhilo
    //  ps : lw des rt, mfc0 des rt, mfhilo des rd
    assign forward1_1D = (|(rs1D ^ 0)) & dec_sign2E.regwrite & (~|(rs1D ^ dec_sign2E.writereg)) ? 4'b1000 :
                        (|(rs1D ^ 0)) & dec_sign2M.regwrite & (~|(rs1D ^ dec_sign2M.writereg)) ? 4'b0111 :
                        (|(rs1D ^ 0)) & dec_sign2M2.regwrite & (~|(rs1D ^ dec_sign2M2.writereg)) ? 4'b0110 :
                        (|(rs1D ^ 0)) & dec_sign2W.regwrite & (~|(rs1D ^ dec_sign2W.writereg)) ? 4'b0101 :
                        (|(rs1D ^ 0)) & dec_sign1E.regwrite & (~|(rs1D ^ dec_sign1E.writereg)) ? 4'b0100 :
                        (|(rs1D ^ 0)) & dec_sign1M.regwrite & (~|(rs1D ^ dec_sign1M.writereg)) ? 4'b0011 :
                        (|(rs1D ^ 0)) & dec_sign1M2.regwrite & (~|(rs1D ^ dec_sign1M2.writereg)) ? 4'b0010 :
                        (|(rs1D ^ 0)) & dec_sign1W.regwrite & (~|(rs1D ^ dec_sign1W.writereg)) ? 4'b0001 :
                        4'b0000;
    assign forward1_2D = (|(rt1D ^ 0)) & dec_sign2E.regwrite & (~|(rt1D ^ dec_sign2E.writereg)) ? 4'b1000 :
                        (|(rt1D ^ 0)) & dec_sign2M.regwrite & (~|(rt1D ^ dec_sign2M.writereg)) ? 4'b0111 :
                        (|(rt1D ^ 0)) & dec_sign2M2.regwrite & (~|(rt1D ^ dec_sign2M2.writereg)) ? 4'b0110 :
                        (|(rt1D ^ 0)) & dec_sign2W.regwrite & (~|(rt1D ^ dec_sign2W.writereg)) ? 4'b0101 :
                        (|(rt1D ^ 0)) & dec_sign1E.regwrite & (~|(rt1D ^ dec_sign1E.writereg)) ? 4'b0100 :
                        (|(rt1D ^ 0)) & dec_sign1M.regwrite & (~|(rt1D ^ dec_sign1M.writereg)) ? 4'b0011 :
                        (|(rt1D ^ 0)) & dec_sign1M2.regwrite & (~|(rt1D ^ dec_sign1M2.writereg)) ? 4'b0010 :
                        (|(rt1D ^ 0)) & dec_sign1W.regwrite & (~|(rt1D ^ dec_sign1W.writereg)) ? 4'b0001 :
                        4'b0000;
    assign forward2_1D = (|(rs2D ^ 0)) & dec_sign2E.regwrite & (~|(rs2D ^ dec_sign2E.writereg)) ? 4'b1000 :
                        (|(rs2D ^ 0)) & dec_sign2M.regwrite & (~|(rs2D ^ dec_sign2M.writereg)) ? 4'b0111 :
                        (|(rs2D ^ 0)) & dec_sign2M2.regwrite & (~|(rs2D ^ dec_sign2M2.writereg)) ? 4'b0110 :
                        (|(rs2D ^ 0)) & dec_sign2W.regwrite & (~|(rs2D ^ dec_sign2W.writereg)) ? 4'b0101 :
                        (|(rs2D ^ 0)) & dec_sign1E.regwrite & (~|(rs2D ^ dec_sign1E.writereg)) ? 4'b0100 :
                        (|(rs2D ^ 0)) & dec_sign1M.regwrite & (~|(rs2D ^ dec_sign1M.writereg)) ? 4'b0011 :
                        (|(rs2D ^ 0)) & dec_sign1M2.regwrite & (~|(rs2D ^ dec_sign1M2.writereg)) ? 4'b0010 :
                        (|(rs2D ^ 0)) & dec_sign1W.regwrite & (~|(rs2D ^ dec_sign1W.writereg)) ? 4'b0001 :
                        4'b0000;
    assign forward2_2D = (|(rt2D ^ 0)) & dec_sign2E.regwrite & (~|(rt2D ^ dec_sign2E.writereg)) ? 4'b1000 :
                        (|(rt2D ^ 0)) & dec_sign2M.regwrite & (~|(rt2D ^ dec_sign2M.writereg)) ? 4'b0111 :
                        (|(rt2D ^ 0)) & dec_sign2M2.regwrite & (~|(rt2D ^ dec_sign2M2.writereg)) ? 4'b0110 :
                        (|(rt2D ^ 0)) & dec_sign2W.regwrite & (~|(rt2D ^ dec_sign2W.writereg)) ? 4'b0101 :
                        (|(rt2D ^ 0)) & dec_sign1E.regwrite & (~|(rt2D ^ dec_sign1E.writereg)) ? 4'b0100 :
                        (|(rt2D ^ 0)) & dec_sign1M.regwrite & (~|(rt2D ^ dec_sign1M.writereg)) ? 4'b0011 :
                        (|(rt2D ^ 0)) & dec_sign1M2.regwrite & (~|(rt2D ^ dec_sign1M2.writereg)) ? 4'b0010 :
                        (|(rt2D ^ 0)) & dec_sign1W.regwrite & (~|(rt2D ^ dec_sign1W.writereg)) ? 4'b0001 :
                        4'b0000;
    assign id_cache_stall=d_cache_stall|i_cache_stall;

    wire branch1_ok = pred_take1D;
    wire pc_change1D = (jump1D | branch1_ok);
    wire branch2_ok = pred_take2D;
    wire pc_change2D = (jump2D | branch2_ok);

    assign fulsh_ex = flush_exception_masterM | flush_exception_slaveM;
    wire only_one = master_only_oneD | slave_only_oneD  | (dec_sign1D.regwrite 
                & (dec_sign2D.read_rs & rs2D == dec_sign1D.writereg 
                |  dec_sign2D.read_rt & rt2D == dec_sign1D.writereg))
                | (dec_sign2D.hilo_read & dec_sign1D.hilo_write)
                | (dec_sign2D.cp0_read & dec_sign1D.cp0_write);
    wire muldiv_conflict = dec_sign1D.DivMulEn & dec_sign2D.DivMulEn & ~dec_sign2D.hilo_read;
    wire pred_failed = pred_failed_masterE | pred_failed_slaveE;
    
    assign longest_stall=id_cache_stall | alu_stallE;

    // Is mfc0 mfhilo lw and Operand is the same 
    assign stallDblank= (((forward1_1D == 4'b1000 | forward1_1D == 4'b0100 | forward1_2D == 4'b1000 | forward1_2D == 4'b0100) & (dec_sign1E.is_mfc | dec_sign1E.mem_read))
                        |((forward2_1D == 4'b1000 | forward2_1D == 4'b0100 | forward2_2D == 4'b1000 | forward2_2D == 4'b0100) & (dec_sign2E.is_mfc | dec_sign2E.mem_read))  
                        |((forward1_1D == 4'b0011 | forward1_1D == 4'b0111 | forward1_2D == 4'b0011 | forward1_2D == 4'b0111)& (mem_read1M))
                        |((forward2_1D == 4'b0011 | forward2_1D == 4'b0111 | forward2_2D == 4'b0011 | forward2_2D == 4'b0111)& (mem_read2M)));

    assign stallF = ~fulsh_ex & (id_cache_stall | alu_stallE | stallDblank  | only_one);
    assign icache_Ctl = d_cache_stall | alu_stallE| stallDblank  | only_one;
    assign stallF2 =  id_cache_stall | alu_stallE| stallDblank  | only_one;

    assign stall_masterD =  id_cache_stall| alu_stallE | stallDblank ;
    assign stall_slaveD = id_cache_stall| alu_stallE | stallDblank  | only_one;

    assign stall_masterE =  id_cache_stall| alu_stallE ;
    assign stall_slaveE =  id_cache_stall| alu_stallE ;

    assign stall_masterM =  id_cache_stall| alu_stallE ;
    assign stall_slaveM =  id_cache_stall| alu_stallE ;

    assign stall_masterM2 = id_cache_stall| alu_stallE;
    assign stall_slaveM2 = id_cache_stall| alu_stallE;
    
    assign stall_masterW =  ~fulsh_ex & (id_cache_stall | alu_stallE);
    assign stall_slaveW =  ~fulsh_ex & (id_cache_stall | alu_stallE);

    assign flushF = 1'b0;

    assign flushF2 = fulsh_ex | pred_failed | ((pc_change1D | pc_change2D) & ~stallF2); 

    assign flush_masterD = fulsh_ex | pred_failed | ((pc_change1D | only_one)    & ~stall_masterD);
    assign flush_slaveD = fulsh_ex | pred_failed  | ((pc_change1D | pc_change2D) & ~stall_slaveD);

    assign flush_masterE = fulsh_ex | ((pred_failed_masterE |stallDblank | muldiv_conflict) & ~stall_masterE);
    assign flush_slaveE = fulsh_ex  | ((pred_failed | stallDblank | only_one) & ~stall_slaveE) ;

    assign flush_masterM = fulsh_ex;
    assign flush_slaveM = fulsh_ex;

    assign flush_masterM2 = flush_exception_masterM;
    assign flush_slaveM2 = fulsh_ex;
    
    assign flushW = 1'b0;
endmodule
