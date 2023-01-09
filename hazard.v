`timescale 1ns / 1ps


module hazard(
    input wire i_cache_stall,
	input wire d_cache_stall,
    input wire alu_stallE,

    input wire flush_jump_conflictE, flush_pred_failedM, flush_exceptionM,

    input wire [4:0] rsE,
    input wire [4:0] rtE,  //寄存器序号
    input wire regwriteM,
    input wire regwriteW,  //写寄存器信号
    input wire [4:0] writeregM,
    input wire [4:0] writeregW,  //写寄存器序号

    input wire mem_readM,   //读mem信号
    
    output wire stallF, stallD, stallE, stallM, stallW,
    output wire flushF, flushD, flushE, flushM, flushW,  //流水线控制
    output wire longest_stall,

    output wire [1:0] forward_1E, forward_2E //00-> NONE, 01-> MEM, 10-> WB (LW instr)
);
    wire id_cache_stall;
    // 数据冒险，前推片选信号
    assign forward_1E = rsE != 0 && regwriteM && (rsE == writeregM) ? 2'b01 :
                        rsE != 0 && regwriteW && (rsE == writeregW) ? 2'b10 :
                        2'b00;
    assign forward_2E = regwriteM && (rtE == writeregM) ? 2'b01 :
                        regwriteW && (rtE == writeregW) ? 2'b10 :
                        2'b00;
    assign id_cache_stall=d_cache_stall|i_cache_stall;

    assign longest_stall=id_cache_stall|alu_stallE;

    assign stallF = ~flush_exceptionM & (id_cache_stall | alu_stallE);//
    assign stallD =  id_cache_stall| alu_stallE;
    assign stallE =  id_cache_stall| alu_stallE;
    assign stallM =  id_cache_stall;
    assign stallW =  ~flush_exceptionM &id_cache_stall;  // 不暂停,会减少jr等指令冲突;

    assign flushF = 1'b0;
    assign flushD = flush_exceptionM | flush_pred_failedM | (flush_jump_conflictE & ~stallD); //       //EX: jr(冲突), MEM: lw这种情况时，flush_jump_conflictE会导致暂停在D阶段jr的延迟槽指令消失
    assign flushE = flush_exceptionM | (flush_pred_failedM & ~longest_stall) ;  //EX: div, MEM: beq, beq预测失败，要flush D和E，但由于div暂停在E，因此只需要flushD就可以了
    assign flushM = flush_exceptionM;//控制hilo的写入 
    assign flushW = flush_exceptionM;
endmodule
