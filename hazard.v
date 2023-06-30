`timescale 1ns / 1ps


module hazard(
    input wire i_cache_stall,
	input wire d_cache_stall,
    input wire alu_stallE, 

    input wire flush_jump_conflictE, flush_pred_failedM, flush_exceptionM,

    input wire is_mfcE, // cp0 read sign
    input wire hilotoregE, //hilo read sign
    input wire [4:0] rsD,  // operand
    input wire [4:0] rtD, 
    input wire regwriteE,
    input wire regwriteM,
    input wire regwriteW,  // whether to write reg
    input wire [4:0] writeregE, // write which reg
    input wire [4:0] writeregM,
    input wire [4:0] writeregW,

    input wire mem_readE,   //Ex's Memread sign, lw lb lhb 
    input wire mem_readM, 
    
    output wire stallF, stallD, stallE, stallM, stallW,
    output wire flushF, flushD, flushE, flushM, flushW,
    output wire longest_stall,

    output wire [1:0] forward_1D, forward_2D //00-> NONE, 01-> MEM, 10-> WB (LW instr), 11 -> ex
);
    wire stallDblank;
    wire id_cache_stall;
    //  1、 if Ex、Mem or Wb is same
    //  2、 And if ExInst is lw or Mfhilo
    //  ps : lw des rt, mfc0 des rt, mfhilo des rd
    assign forward_1D = (|(rsD ^ 0)) & regwriteE & (~|(rsD ^ writeregE)) ? 2'b11 :
                        (|(rsD ^ 0)) & regwriteM & (~|(rsD ^ writeregM)) ? 2'b01 :
                        (|(rsD ^ 0)) & regwriteW & (~|(rsD ^ writeregW)) ? 2'b10 :
                        2'b00;
    assign forward_2D = (|(rtD ^ 0)) & regwriteE & (~|(rtD ^ writeregE)) ? 2'b11 :
                        (|(rtD ^ 0)) & regwriteM & (~|(rtD ^ writeregM)) ? 2'b01 :
                        (|(rtD ^ 0)) & regwriteW & (~|(rtD ^ writeregW)) ? 2'b10 :
                        2'b00;
    assign id_cache_stall=d_cache_stall|i_cache_stall;

    assign longest_stall=id_cache_stall|alu_stallE;
    // Is mfc0 mfhilo lw and Operand is the same 
    assign stallDblank= ((~|(forward_2D ^ 2'b11)) & (is_mfcE | mem_readE)) | ((~|(forward_1D ^ 2'b11)) & hilotoregE) ;
    assign stallF = (~flush_exceptionM & (id_cache_stall | alu_stallE))| stallDblank;
    assign stallD =  id_cache_stall| alu_stallE | stallDblank;
    assign stallE =  id_cache_stall| alu_stallE;
    assign stallM =  id_cache_stall;
    assign stallW =  ~flush_exceptionM &id_cache_stall;

    assign flushF = 1'b0;
    assign flushD = flush_exceptionM | flush_pred_failedM | (flush_jump_conflictE & ~stallD); 
    assign flushE = flush_exceptionM | (flush_pred_failedM & ~longest_stall) |stallDblank ; 
    assign flushM = flush_exceptionM;
    assign flushW = flush_exceptionM;
endmodule
