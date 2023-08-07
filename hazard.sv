module hazard(
    input wire i_cache_stall,
	input wire d_cache_stall,
    input wire alu_stallE, 

    input wire flush_pred_failedE, flush_exceptionM, jumpD,
    input wire branchD, branchE, pre_right, pred_takeD,

    input wire is_mfcE, // cp0 read sign
    input wire hilotoregE, //hilo read sign
    input wire [4:0] rsD,  // operand
    input wire [4:0] rtD, 
    input wire regwriteE,
    input wire regwriteM,
    input wire regwriteM2,
    input wire regwriteW,  // whether to write reg
    input wire [4:0] writeregE, // write which reg
    input wire [4:0] writeregM,
    input wire [4:0] writeregM2,
    input wire [4:0] writeregW,

    input wire mem_readE,   //Ex's Memread sign, lw lb lhb 
    input wire mem_readM, 
    
    output wire stallF, stallF2, stallD, stallE, stallM, stallM2, stallW,
    output wire flushF, flushF2, flushD, flushE, flushM, flushM2, flushW,
    output wire longest_stall, stallDblank, icache_Ctl,

    output wire [2:0] forward_1D, forward_2D //000-> NONE, 001-> WRITE, 010-> M2, 011 -> M , 100 -> E
);
    
    wire id_cache_stall;
    //  1、 if Ex、Mem or Wb is same
    //  2、 And if ExInst is lw or Mfhilo
    //  ps : lw des rt, mfc0 des rt, mfhilo des rd
    assign forward_1D = ((rsD != 0)) & regwriteE & ((rsD == writeregE)) ? 3'b100 :
                        ((rsD != 0)) & regwriteM & ((rsD == writeregM)) ? 3'b011 :
                        ((rsD != 0)) & regwriteM2 & ((rsD == writeregM2)) ? 3'b010 :
                        ((rsD != 0)) & regwriteW & ((rsD == writeregW)) ? 3'b001 :
                        3'b000;
    assign forward_2D = ((rtD != 0)) & regwriteE & ((rtD == writeregE)) ? 3'b100 :
                        ((rtD != 0)) & regwriteM & ((rtD == writeregM)) ? 3'b011 :
                        ((rtD != 0)) & regwriteM2 & ((rtD == writeregM2)) ? 3'b010 :
                        ((rtD != 0)) & regwriteW & ((rtD == writeregW)) ? 3'b001 :
                        3'b000;
    assign id_cache_stall=d_cache_stall|i_cache_stall;

    wire branch_ok =  pred_takeD ;
    
    assign longest_stall=id_cache_stall|alu_stallE;
    // Is mfc0 mfhilo lw and Operand is the same 
    assign stallDblank= (((((forward_2D == 3'b100)) | ((forward_1D == 3'b100))) & (is_mfcE | mem_readE)) 
                | (((((forward_1D == 3'b011))) | (((forward_2D == 3'b011))))& (mem_readM)));
    assign stallF = ~flush_exceptionM & (id_cache_stall | alu_stallE | stallDblank);
    assign icache_Ctl = d_cache_stall | alu_stallE| stallDblank;
    assign stallF2 =  id_cache_stall | alu_stallE| stallDblank;
    assign stallD =  id_cache_stall| alu_stallE | stallDblank;
    assign stallE =  id_cache_stall| alu_stallE;
    assign stallM =  id_cache_stall| alu_stallE;
    assign stallM2 = id_cache_stall| alu_stallE;
    assign stallW =  ~flush_exceptionM &(id_cache_stall | alu_stallE);

    assign flushF = 1'b0;
    assign flushF2 = flush_exceptionM | flush_pred_failedE | ((jumpD | branch_ok) & ~stallF2); 
    assign flushD = flush_exceptionM | (flush_pred_failedE & ~stallD); 
    assign flushE = flush_exceptionM | (stallDblank & ~stallE ) ; 
    assign flushM = flush_exceptionM;
    assign flushM2 = flush_exceptionM;
    assign flushW = 1'b0;
endmodule
