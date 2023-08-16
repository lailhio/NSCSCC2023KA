module datapath(

	input wire clk,rst,
	
	input wire  [5 :0] ext_int, //异常处理
    
    //inst
    output wire [31:0] PC_IF1,  //指令地址
    output wire        inst_enF,  //使能
    input wire  [31:0] instrF2,  //注：instr ram时钟取反
    input wire         i_cache_stall,

    //data
    output wire mem_enE,                    
    output wire [31:0] mem_addrE,     //写地址
    input  wire [31:0] mem_rdataM,    //读数据
    output wire [3 :0] mem_write_selectE,      //写使能
    output wire [31:0] writedataE,    //写数据
    output wire [1:0] cpu_data_size,
    input wire         d_cache_stall,

    output wire        alu_stallE, icache_Ctl, 
    output wire        dcache_ctl,
      // TLB
    output wire flushM,stallF2,
    output wire TLBP,
    output wire TLBR,
    output wire TLBWI,
    output wire TLBWR,
    input wire [31:0] EntryHi_to_cp0,
    input wire [31:0] PageMask_to_cp0,
    input wire [31:0] EntryLo0_to_cp0,
    input wire [31:0] EntryLo1_to_cp0,
    input wire [31:0] Index_to_cp0,

    output wire [31:0] EntryHi_from_cp0,
    output wire [31:0] PageMask_from_cp0,
    output wire [31:0] EntryLo0_from_cp0,
    output wire [31:0] EntryLo1_from_cp0,
    output wire [31:0] Index_from_cp0,
    output wire [31:0] Random_from_cp0,

        //异常
    input wire inst_tlb_refillF, inst_tlb_invalidF,
    input wire data_tlb_refillM, data_tlb_invalidM, data_tlb_modifyM,
    output wire mem_readE, mem_writeE,
	//debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata,
    output wire [31:0] debug_cp0_count,
    output wire [31:0] debug_cp0_random,
    output wire [31:0] debug_cp0_cause,
    output wire debug_int,
    output wire debug_commit
    );
	
	//--------InstFetch1 stage----------
	wire [31:0] PcPlus4F, PcPlus8F;    //pc
    
    wire pc_errorF;  // pc错误

    //--------InstFetch2 stage----------
	wire [31:0] PcPlus4F2, PcPlus8F2;    //pc
     wire [31:0] PcF2;    //pc
    wire is_in_delayslot_iF2; // 此时的D阶段（即上一条指令）是否为跳转指令
	//----------decode stage---------
	wire[5:0] aluopD;
	wire[7:0] alucontrolD;
	wire [31:0] instrD;  //指令
    wire [31:0] PcD, PcPlus4D, PcPlus8D;  //pc
    wire [31:0] src_a1D, src_b1D,src_aD, src_bD; //alu输入（操作数
    wire [31:0] rd1D, rd2D, immD, pc_branchD, pc_jumpD;  //寄存器读出数据 立即数 pc分支 跳转
    wire        pred_takeD, branchD, jumpD;  //立即数扩展 分支预测 branch jump信号
    wire        flush_pred_failedE;  //分支预测失败

    wire [2 :0] branch_judge_controlD; //分支判断控制
	wire 		sign_exD;          //立即数是否为符号扩展
	wire [1:0] 	regdstD;    	//写寄存器选择  00-> rd, 01-> rt, 10-> $ra
	wire 		is_immD;       //alu srcb选择 0->rd2D, 1->immD
    wire [4 :0] writeregD; //写寄存器号
	wire 		regwriteD;//写寄存器堆使

	wire 		mem_readD, mem_writeD;
	wire 		memtoregD;       	//result选择 0->aluout, 1->read_data
	wire 		hilotoregD;			// 00--aluoutM; 01--hilo_out; 10 11--rdataM;
	wire 		riD;
	wire 		breakD, syscallD, eretD;
	wire 		cp0_writeD;
	wire 		cp0_to_regD;
	wire		is_mfcD;
	wire        mfhiD;
	wire        mfloD;
    wire        is_in_delayslot_iD;//指令是否在延迟槽
    wire [1:0]  forward_1D;
    wire [1:0]  forward_2D;
	//-------execute stage----------
	wire [31:0] pcE, PcPlus4E, PcPlus8E; //pc pc+4 寄存器号 写内存 立即数
    wire        pred_takeE;  //分支预测
    wire [1 :0] regdstE;  //写回选择信号, 00-> rd, 01-> rt, 10-> $ra
    wire [7 :0] alucontrolE;  //alu控制信号

    wire [31:0] src_a1E, src_b1E; //alu输入（操作数
    wire [31:0] src_aE, src_bE; //alu输入（操作数
    wire [31:0] aluoutE; //alu输出
    wire [4 :0] writeregE; //写寄存器号
    wire        branchE; //分支信号

    wire [31:0] instrE;
    wire [31:0] pc_jumpE;  //jump pc
    wire        regwriteE;	//寄存器写
    // wire        alu_stallE;  //alu暂停
    wire        actual_takeE;  //分支预测 实际结果
    wire [2 :0] branch_judge_controlE; //分支判断控制
	wire        memtoregE, mem_readE, mem_writeE;
    wire [1:0]  hilo_selectE;  //高位1表示是mhl指令，0表示是乘除法
                              //低位1表示是用hi，0表示用lo
	wire        hilotoregE;//hilo到寄存器
	wire        breakE, syscallE;
	wire        riE,eretE;
	wire        cp0_writeE;
	wire        cp0_to_regE;
	wire 		is_mfcE;
	wire        mfhiE;
	wire        mfloE;
 // 异常处理信号
    wire        is_in_delayslot_iE; //是否处于延迟槽
    wire        overflowE; //溢出
    wire        trapE; //自陷
	
	//----------mem stage--------
	wire [31:0] pcM;  // pc
    wire [31:0] aluoutM; //alu输出
    wire [4:0] 	writeregM; //写寄存器号
    wire [31:0] instrM;  //指令
    // wire        mem_readM; //读内存
    wire        mem_writeE; //写内存
    wire        regwriteM;  //寄存器写
    wire        memtoregM;  //写回寄存器选择信号
    wire        pre_right;  // 预测正确
    wire        branchM; // 分支信号
    wire [31:0] pc_branchE; //分支跳转地址

    wire [31:0] result_rdataM;
    wire [31:0] cp0_countE, cp0_causeE, cp0_randomE;
    wire [31:0] cp0_outE;
	wire		is_mfcM;

    wire [31:0] src_b1M;
    //异常处理信号 exception
    wire        interuptE;  //指令不存在
    wire        addrErrorLwE, addrErrorSwE; //访存指令异常
    wire        pcErrorE;  //pc异常

	// cp0	
    wire        flush_exceptionE;  // 发生异常时需要刷新流水线
    wire [31:0] pc_exceptionE; //异常处理的地址0xbfc0_0380，若为eret指令 则为返回地址
    wire        pc_trapE; // 发生异常时pc特殊处理
    wire        cp0_to_regM;
    //------writeback stage----------
	wire [31:0] resultori_M;
	wire [31:0] resultM;
    wire [31:0] cp0_countM, cp0_causeM, cp0_randomM;
	//------writeback stage----------
    wire interuptM, mem_writeM;  //指令不存在
	wire [4:0] writeregW;//写寄存器号
	wire regwriteW;
	wire [31:0] resultW;
    wire [31:0] aluoutW;
    wire [31:0] pcW;
    wire [31:0] cp0_countW, cp0_causeW, cp0_randomW;
    //------stall sign---------------
    wire stallF, stallF2, stallD, stallE, stallM, stallW ,stallDblank,  longest_stall;
    wire flushF, flushF2, flushD, flushE, flushM, flushW;
//------------------------------------------Data------------------------------------------
	//--------------------debug---------------------
    assign debug_wb_pc          = pcW;
    assign debug_wb_rf_wen      = {4{regwriteW & ~stallW }};
    assign debug_wb_rf_wnum     = writeregW;
    assign debug_wb_rf_wdata    = resultW;
    assign debug_cp0_count      = cp0_countW;
    assign debug_cp0_random     = cp0_randomW;
    assign debug_cp0_cause      = cp0_causeW;
    assign debug_int            = interuptW;
    assign debug_commit         = ~stallW;
    
    //--------------------------------------Fetch------------------------------------------------
    
    assign inst_enF = ~flush_exceptionE & ~pc_errorF & ~flush_pred_failedE;
    // pc+4
    assign PcPlus4F = PC_IF1 + 4;
    assign PcPlus8F = PC_IF1 + 8;
    assign pc_errorF = ((PC_IF1[1:0] == 2'b0)) ? 1'b0 : 1'b1; 
    // pc reg
    pc_reg pc(
        .clk(clk), .rst(rst), .stallF(stallF),
        .branchD(branchD), .branchE(branchE), .pre_right(pre_right), .actual_takeE(actual_takeE),
        .pred_takeD(pred_takeD), .pc_trapE(pc_trapE), .jumpD(jumpD),

        .pc_exceptionE(pc_exceptionE), .PcPlus8E(PcPlus8E), .pc_branchE(pc_branchE),
        .pc_jumpD(pc_jumpD), .pc_branchD(pc_branchD), .PcPlus4F(PcPlus4F),

        .pc(PC_IF1)
    );
    
    
	//----------------------------------------InstFetch2------------------------------------------------
    wire inst_enF2;
    wire [31:0] instr_validF2;
    flopstrc #(32) flopPcplus4F2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PcPlus4F),.out(PcPlus4F2));
    flopstrc #(32) flopPcplus8F2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PcPlus8F),.out(PcPlus8F2));
    flopstrc #(32) flopPcF2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PC_IF1),.out(PcF2));
    flopstrc #(1) flopInstEnF2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(inst_enF),.out(inst_enF2));
    assign instr_validF2 = {32{inst_enF2}}&instrF2;  //丢掉无效指令
    assign is_in_delayslot_iF2 = branchD | jumpD; //通过前一条指令，判断是否是延迟槽
    //-----------------------InstFetch2Flop------------------------------


	//----------------------------------------Decode------------------------------------------------
    flopstrc #(32) flopPcplus4D(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),.in(PcPlus4F2),.out(PcPlus4D));
    flopstrc #(32) flopPcplus8D(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),.in(PcPlus8F2),.out(PcPlus8D));
    flopstrc #(32) flopPcD(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),.in(PcF2),.out(PcD));
    flopstrc #(32) flopInstD(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),.in(instr_validF2),.out(instrD));
    flopstrc #(1) flopIsdelayD(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),
        .in(is_in_delayslot_iF2),.out(is_in_delayslot_iD));
    //-----------------------DecodeFlop----------------------------------
    wire[5:0] functD;
    wire DivMulEnD, DivMulEnE;
	aludec ad(functD,aluopD,alucontrolD);
	maindec md(instrD,
		//output
        sign_exD , regdstD, is_immD , regwriteD , writeregD, mem_readD , mem_writeD , memtoregD,
		hilotoregD , riD, breakD , syscallD , eretD , cp0_writeD , cp0_to_regD,
        mfhiD , mfloD , is_mfcD,  aluopD, functD , branch_judge_controlD , DivMulEnD);

    //扩展立即数
    signext signex(sign_exD,instrD[15:0],immD);
	//regfile，                             rs            rt
	regfile rf(clk,rst,stallW,regwriteW,instrD[25:21],instrD[20:16],writeregW,resultW,rd1D,rd2D);
    // 立即数左移2 + pc+4得到分支跳转地址   
    assign pc_branchD = {immD[29:0], 2'b00} + PcPlus4D;
    //前推至ID阶段
    mux4 #(32) mux4_forward_1D(rd1D, resultW, resultM, aluoutE, forward_1D, src_a1D);
    mux4 #(32) mux4_forward_2D(rd2D, resultW, resultM, aluoutE, forward_2D, src_b1D);
    //choose jump
    mux5 #(32) mux8_jump(rd1D, resultW, resultM, aluoutE, PcPlus8D, {jumpD | branchD, forward_1D}, src_aD);
    //choose imm
    mux5 #(32) mux8_imm(rd2D, resultW, resultM, aluoutE, immD, {is_immD ,forward_2D}, src_bD);
	// BranchPredict
    BranchPredict branch_predict(
        .clk(clk), .rst(rst),
        .flushD(flushD),.stallD(stallD),.instrD(instrD),
        
        .immD(immD),
        .PcF2(PcF2),
        .pcE(pcE),
        .branchE(branchE),
        .actual_takeE(actual_takeE),

        .branchD(branchD),
        .pred_takeD(pred_takeD)
    );
    // jump, assign Logic
    jump_control jump_control(
        .instrD(instrD),
        .PcPlus4D(PcPlus4D),
        .src_a1D(src_a1D),

        .jumpD(jumpD),                      //是jump类指令(j, jr)
        .pc_jumpD(pc_jumpD)                 //D阶段最终跳转地址
    );
	//----------------------------------Execute------------------------------------
    flopstrc #(32) flopPcE(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(PcD),.out(pcE));
    flopstrc #(32) flopInstE(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(instrD),.out(instrE));
    flopstrc #(32) flopSrca1E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(src_a1D),.out(src_a1E));
    flopstrc #(32) flopSrcb1E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(src_b1D),.out(src_b1E));
    flopstrc #(32) flopSrcaE(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(src_aD),.out(src_aE));
    flopstrc #(32) flopSrcbE(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(src_bD),.out(src_bE));
    flopstrc #(32) flopPcplus4E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(PcPlus4D),.out(PcPlus4E));
    flopstrc #(32) flopPcplus8E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(PcPlus8D),.out(PcPlus8E));
    flopstrc #(32) flopPcbranchE(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(pc_branchD),.out(pc_branchE));
    flopstrc #(7) flopSign1E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),
        .in({branchD,pred_takeD,is_in_delayslot_iD,regwriteD,riD,breakD,hilotoregD}),
        .out({branchE,pred_takeE,is_in_delayslot_iE,regwriteE,riE,breakE,hilotoregE}));
    flopstrc #(11) flopSign2E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),
        .in({memtoregD,mem_writeD,mem_readD,syscallD,eretD,cp0_to_regD,is_mfcD,mfloD,mfhiD,cp0_writeD, DivMulEnD}),
        .out({memtoregE,mem_writeE,mem_readE,syscallE,eretE,cp0_to_regE,is_mfcE,mfloE,mfhiE,cp0_writeE, DivMulEnE}));
    flopstrc #(18) flopSign3E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),
        .in({alucontrolD,branch_judge_controlD,writeregD,regdstD}),
        .out({alucontrolE,branch_judge_controlE,writeregE,regdstE}));

    
    //-----------------------ExFlop---------------------
	//ALU
    alu aluitem(
        //input
        .clk(clk),.rst(rst),.stallE(stallE),.flushE(flushE),
        .src_aE(src_aE), .src_bE(src_bE), .cp0_outE(cp0_outE),
        .alucontrolE(alucontrolE),.sa(instrE[10:6]),.msbd(instrE[15:11]),
        .mfhiE(mfhiE), .mfloE(mfloE), .flush_exceptionE(flush_exceptionE), .DivMulEnE(DivMulEnE), 
        //output
        .alustallE(alu_stallE),
        .aluoutE(aluoutE) , .overflowE(overflowE), .trapE(trapE)
    );
    
	//在execute阶段得到真实branch跳转情况
    branch_check branch_check(
        .branch_judge_controlE(branch_judge_controlE),
        .rs_valueE(src_a1E),
        .rt_valueE(src_b1E),
        .actual_takeE(actual_takeE)
    );
    //分支预测结果
    assign pre_right = ~flush_pred_failedE; 
    assign flush_pred_failedE = pred_takeE ^ actual_takeE;
    
    assign pc_jumpE =src_a1E; //jr指令 跳转到rs
    assign mem_enE = (mem_readE  |  mem_writeE) & ~flush_exceptionE; //意外刷新时需要
    wire [31:0] addressE = src_aE + src_bE ;
    // Assign Logical
    mem_control mem_control(
        .instrE(instrE), .instrM(instrM), .addressE(addressE), .addressM(aluoutM),
    
        .data_wdataE(src_b1E),    //原始的wdata
        .rt_valueM(src_b1M),
        .writedataE(writedataE),    //新的wdata
        .mem_write_selectE(mem_write_selectE),
        .data_addrE(mem_addrE),
        .mem_rdataM(mem_rdataM), .data_rdataM(result_rdataM),
        .data_size(cpu_data_size),

        .addr_error_sw(addrErrorSwE), .addr_error_lw(addrErrorLwE)  
    );

    
    //后两位不为0
    assign pcErrorE = (pcE[1:0] != 2'b00); 

    cp0_exception cp0_exception(
        .clk(clk), .rst(rst),
        .stallM(stallM), .we_i(cp0_writeE),
        .waddr_i(instrE[15:11]), .raddr_i(instrE[15:11]),
        .sel_addr(instrE[2:0]), .data_i(src_b1E), .int_i(ext_int),
        .tlb_typeM(tlb_typeE),
        .entry_lo0_in(EntryLo0_to_cp0),
        .entry_lo1_in(EntryLo1_to_cp0),
        .page_mask_in(PageMask_to_cp0),
        .entry_hi_in(EntryHi_to_cp0),
        .index_in(Index_to_cp0),
        .entry_hi_W(EntryHi_from_cp0),
        .page_mask_W(PageMask_from_cp0),
        .entry_lo0_W(EntryLo0_from_cp0), 
        .entry_lo1_W(EntryLo1_from_cp0),
        .index_W(Index_from_cp0),
//tlb exception
        .mem_read_enM(mem_readE),
        .mem_write_enM(mem_writeE),
        .inst_tlb_refill(inst_tlb_refillM),
        .inst_tlb_invalid(inst_tlb_invalidM),
        .data_tlb_refill(data_tlb_refillM),
        .data_tlb_invalid(data_tlb_invalidM),
        .data_tlb_modify(data_tlb_modifyM),

        .current_inst_addr_i(pcE),
        .is_in_delayslot_i(is_in_delayslot_iE),
        .ri(riE), .break_exception(breakE), .syscall(syscallE), .overflow(overflowE), .trap(trapE), 
        .addrErrorSw(addrErrorSwE), .addrErrorLw(addrErrorLwE), .pcError(pcErrorE), .eretE(eretE),
        .aluoutE(aluoutE),
        .cause_o(cp0_causeE),
        .data_o(cp0_outE),
        // .timer_int_o,
        .count_o(cp0_countE),
        .random_o(cp0_randomE),
        .flush_exception(flush_exceptionE),
        .pc_exception(pc_exceptionE),
        .pc_trap(pc_trapE), .interupt(interuptE)
    );

	//-------------------------------------Memory----------------------------------------
	flopstrc #(32) flopPcM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(pcE),.out(pcM));
	flopstrc #(32) flopAluM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(aluoutE),.out(aluoutM));
	flopstrc #(32) flopRtvalueM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(src_b1E),.out(src_b1M));
	flopstrc #(32) flopInstrM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(instrE),.out(instrM));
    flopstrc #(5) flopSign1M(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),
        .in({regwriteE,branchE,mem_writeE,memtoregE, interuptE}),
        .out({regwriteM,branchM,mem_writeM,memtoregM, interuptM}));
    flopstrc #(2) flopSign2M(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),
        .in({cp0_to_regE,is_mfcE}),
        .out({cp0_to_regM,is_mfcM}));
    flopstrc #(5) flopWriteregM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),
        .in({writeregE}),.out({writeregM}));
    //----------------------MemoryFlop------------------------

	//------------------Memory2_Flop--------------------------
    mux2 #(32) mux2_memtoreg(aluoutM, result_rdataM, memtoregM, resultM);
	//-------------------------------------Write_Back-------------------------------------------------
    wire is_mfcW, interuptW;
    wire [31:0] instrW; // for debug
	flopstrc #(8) flopWriregW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),
            .in({writeregM,regwriteM,is_mfcM, interuptM}),
            .out({writeregW,regwriteW,is_mfcW, interuptW}));
	flopstrc #(32) flopInstrW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(instrM),.out(instrW));
	flopstrc #(32) flopPcW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(pcM),.out(pcW));
	flopstrc #(32) flopRamdomW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(cp0_randomM),.out(cp0_randomW));
	flopstrc #(32) flopCountW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(cp0_countM),.out(cp0_countW));
	flopstrc #(32) flopCauseW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(cp0_causeM),.out(cp0_causeW));
	flopstrc #(32) flopAluoutW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(aluoutM),.out(aluoutW));
	flopstrc #(32) flopResW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(resultM),.out(resultW));
	//------------------Write_Back_Flop--------------------------

	//hazard detection
    wire Blank_SL = ((addressE[31:2] == aluoutM[31:2])) & mem_writeM &  mem_readE;
	hazard hazard0(
        .i_cache_stall(i_cache_stall),
        .d_cache_stall(d_cache_stall),
        .alu_stallE(alu_stallE),

        .jumpD                  (jumpD),
        .flush_pred_failedE     (flush_pred_failedE),
        .flush_exceptionE       (flush_exceptionE),

        .branchD(branchD), .branchE(branchE), .pre_right(pre_right), .pred_takeD(pred_takeD),

        .rsD(instrD[25:21]),
        .rtD(instrD[20:16]),
        .is_mfcE(is_mfcE),
        .hilotoregE(hilotoregE),
        .regwriteE(regwriteE),
        .regwriteM(regwriteM),
        // .regwriteM2(regwriteM2),
        .regwriteW(regwriteW),
        .writeregE(writeregE),
        .writeregM(writeregM),
        // .writeregM2(writeregM2),
        .writeregW(writeregW),
        .mem_readE(mem_readE),
        // .mem_readM(mem_readM),
        
        .Blank_SL(Blank_SL),
        .stallF(stallF), .stallF2(stallF2), .stallD(stallD), .stallE(stallE), .stallM(stallM), .stallW(stallW),
        .flushF(flushF), .flushF2(flushF2), .flushD(flushD), .flushE(flushE), .flushM(flushM), .flushW(flushW),
        .longest_stall(longest_stall), .stallDblank(stallDblank), .icache_Ctl(icache_Ctl), .dcache_ctl(dcache_ctl),
        .forward_1D(forward_1D), .forward_2D(forward_2D)
    );
	
endmodule