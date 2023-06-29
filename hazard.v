`timescale 1ns / 1ps


module hazard(
    input wire i_cache_stall,
	input wire d_cache_stall,
    input wire alu_stallE, 

    input wire flush_jump_conflictE, flush_pred_failedM, flush_exceptionM,

    input wire [4:0] rsD,
    input wire [4:0] rtD,  //寄存器序号
    input wire regwriteE,
    input wire regwriteM,
    input wire regwriteW,  //写寄存器信号
    input wire [4:0] writeregE,
    input wire [4:0] writeregM,
    input wire [4:0] writeregW,  //写寄存器序号

    input wire mem_readM,   //读mem信号
    
    output wire stallF, stallD, stallE, stallM, stallW,
    output wire flushF, flushD, flushE, flushM, flushW,  //流水线控制
    output wire longest_stall, stallDblank,

    output wire [1:0] forward_1D, forward_2D //00-> NONE, 01-> MEM, 10-> WB (LW instr), 11 -> ex
);
    wire id_cache_stall;
    //  1、 if Ex、Mem or Wb is same
    //  2、 And if ExInst is lw or Mfhilo
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
    // todo mfc0 mfhilo lw 
    assign stallDblank=(|forward_1D) | (|forward_2D);
    assign stallF = ~flush_exceptionM & (id_cache_stall | alu_stallE);
    assign stallD =  id_cache_stall| alu_stallE;
    assign stallE =  id_cache_stall| alu_stallE;
    assign stallM =  id_cache_stall;
    assign stallW =  ~flush_exceptionM &id_cache_stall;

    assign flushF = 1'b0;
    assign flushD = flush_exceptionM | flush_pred_failedM | (flush_jump_conflictE & ~stallD); 
    assign flushE = flush_exceptionM | (flush_pred_failedM & ~longest_stall) ; 
    assign flushM = flush_exceptionM;//控制hilo的写入 
    assign flushW = flush_exceptionM;
endmodule
