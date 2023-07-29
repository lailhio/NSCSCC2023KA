module datapath(

	input wire clk,rst,
	
	input wire  [5 :0] ext_int, //异常处理
    
    //inst
    output wire [31:0] PC_IF1,  //指令地址
    output wire        inst_enF,  //使能
    input wire  [31:0] instrF2,  //注：instr ram时钟取反
    input wire         i_cache_stall,

    //data
    output wire mem_enM,                    
    output wire [31:0] mem_addrM,     //写地址
    input  wire [31:0] mem_rdataM2,    //读数据
    output wire [3 :0] mem_write_selectM,      //写使能
    output wire [31:0] writedataM,    //写数据
    input wire         d_cache_stall,

    output wire        stallF2, stallM2, 
	//debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
    );
	
	//--------InstFetch1 stage----------
	wire [31:0] PcPlus4F;    //pc
    
    wire pc_errorF;  // pc错误

    wire is_in_delayslot_iF; // 此时的D阶段（即上一条指令）是否为跳转指令
    //--------InstFetch2 stage----------
	wire [31:0] PcPlus4F2;    //pc
    wire [31:0] PcF2;    //pc
    wire is_in_delayslot_iF2; // 此时的D阶段（即上一条指令）是否为跳转指令
	//----------decode stage---------
	wire[5:0] aluopD;
	wire[7:0] alucontrolD;
	wire [31:0] instrD;  //指令
    wire [31:0] PcD, PcPlus4D;  //pc
    wire [31:0] src_a1D, src_b1D,src_aD, src_bD; //alu输入（操作数
    wire [31:0] rd1D, rd2D, immD, pc_branchD, pc_jumpD;  //寄存器读出数据 立即数 pc分支 跳转
    wire        pred_takeD, branchD, jumpD;  //立即数扩展 分支预测 branch jump信号
    wire        flush_pred_failedM;  //分支预测失败

    wire        jump_conflictD;  //jump冲突
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
    wire [2:0]  forward_1D;
    wire [2:0]  forward_2D;
	//-------execute stage----------
	wire [31:0] pcE, pcplus4E; //pc pc+4 寄存器号 写内存 立即数
    wire        pred_takeE;  //分支预测
    wire [1 :0] regdstE;  //写回选择信号, 00-> rd, 01-> rt, 10-> $ra
    wire [7 :0] alucontrolE;  //alu控制信号

    wire [31:0] src_a1E, src_b1E; //alu输入（操作数
    wire [31:0] src_aE, src_bE; //alu输入（操作数
    wire [31:0] aluoutE; //alu输出
    wire [4 :0] writeregE; //写寄存器号
    wire        branchE; //分支信号
    wire [31:0] pc_branchE;  //分支跳转pc

    wire [31:0] instrE;
    wire [31:0] pc_jumpE;  //jump pc
    wire        jump_conflictE; //jump冲突
    wire        regwriteE;	//寄存器写
    wire        alu_stallE;  //alu暂停
    wire        flush_jump_conflictE;  //jump冲突
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
	
	//----------mem stage--------
	wire [31:0] pcM;  // pc
    wire [31:0] aluoutM; //alu输出
    wire [4:0] 	writeregM; //写寄存器号
    wire [31:0] instrM;  //指令
    wire        mem_readM; //读内存
    wire        mem_writeM; //写内存
    wire        regwriteM;  //寄存器写
    wire        memtoregM;  //写回寄存器选择信号
    wire [31:0] resultM;  // mem out
    wire        actual_takeM;  //分支预测 真实结果
    wire        pre_right;  // 预测正确
    wire        pred_takeM; // 预测
    wire        branchM; // 分支信号
    wire [31:0] pc_branchM; //分支跳转地址

    wire [31:0] result_rdataM2;
    wire [31:0] hilo_outM;  //hilo输出
	wire		is_mfcM;

    wire [31:0] src_b1M;
    //异常处理信号 exception
    wire        riM;  //指令不存在
    wire        breakM; //break指令
    wire        syscallM; //syscall指令
    wire        eretM; //eretM指令
    wire        overflowM;  //算数溢出
    wire        addrErrorLwM, addrErrorSwM; //访存指令异常
    wire        pcErrorM;  //pc异常

	// cp0	
    wire [31:0] except_typeM;  // 异常类型
    wire        flush_exceptionM;  // 发生异常时需要刷新流水线
    wire [31:0] pc_exceptionM; //异常处理的地址0xbfc0_0380，若为eret指令 则为返回地址
    wire        pc_trapM; // 发生异常时pc特殊处理
    wire [31:0] badvaddrM;
    wire        is_in_delayslot_iM;
    wire        cp0_to_regM;
    wire        cp0_writeM;
    //------writeback stage----------
	wire [4:0] writeregM2;//写寄存器号
	wire regwriteM2,memtoregM2;
	wire [31:0] resultori_M2;
	wire [31:0] resultM2;
    wire [31:0] aluoutM2;
    wire [31:0] pcM2;
    wire [31:0] instrM2;
    wire [31:0] cp0_statusM2, cp0_causeM2, cp0_epcM2, cp0_outM2;
    wire [31:0] src_b1M2;
	//------writeback stage----------
	wire [4:0] writeregW;//写寄存器号
	wire regwriteW;
	wire [31:0] resultW;
    wire [31:0] pcW;
    //------stall sign---------------
    wire stallF, stallD, stallE, stallM, stallW ,stallDblank,  longest_stall;
    wire flushF, flushF2, flushD, flushE, flushM, flushM2, flushW;
//------------------------------------------Data------------------------------------------
	//--------------------debug---------------------
    assign debug_wb_pc          = pcW;
    assign debug_wb_rf_wen      = {4{regwriteW & ~stallW }};
    assign debug_wb_rf_wnum     = writeregW;
    assign debug_wb_rf_wdata    = resultW;
    // Todo : jal wrong
    //--------------------------------------Fetch------------------------------------------------
    
    assign inst_enF = ~flush_exceptionM & ~pc_errorF & ~flush_pred_failedM & ~flush_jump_conflictE & ~stallDblank;
    // pc+4
    assign PcPlus4F = PC_IF1 + 4;
    assign pc_errorF = (~|(PC_IF1[1:0] ^ 2'b0)) ? 1'b0 : 1'b1; 
    assign is_in_delayslot_iF = branchD | jumpD; //通过前一条指令，判断是否是延迟槽
    // pc reg
    pc_reg pc(
        .clk(clk), .rst(rst), .stallF(stallF),
        .branchD(branchD), .branchM(branchM), .pre_right(pre_right), .actual_takeM(actual_takeM),
        .pred_takeD(pred_takeD), .pc_trapM(pc_trapM), .jumpD(jumpD),
        .jump_conflictD(jump_conflictD), .jump_conflictE(jump_conflictE),

        .pc_exceptionM(pc_exceptionM), .pcplus4E(pcplus4E), .pc_branchM(pc_branchM),
        .pc_jumpE(pc_jumpE), .pc_jumpD(pc_jumpD), .pc_branchD(pc_branchD), .PcPlus4F(PcPlus4F),

        .pc(PC_IF1)
    );
    
	//----------------------------------------InstFetch2------------------------------------------------
    flopstrc #(32) flopPcplusF2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PcPlus4F),.out(PcPlus4F2));
    flopstrc #(32) flopPcF2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PC_IF1),.out(PcF2));
    flopstrc #(1) flopInstEnF2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(inst_enF),.out(inst_enF2));
    flopstrc #(1) flopIsdelayF2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),
        .in(is_in_delayslot_iF),.out(is_in_delayslot_iF2));
        
    wire [31:0] instr_validF2;
    wire inst_enF2;
    assign instr_validF2 = {32{inst_enF2}}&instrF2;  //丢掉无效指令
    //-----------------------InstFetch2Flop------------------------------


	//----------------------------------------Decode------------------------------------------------
    flopstrc #(32) flopPcplusD(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),.in(PcPlus4F2),.out(PcPlus4D));
    flopstrc #(32) flopPcD(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),.in(PcF2),.out(PcD));
    flopstrc #(32) flopInstD(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),.in(instr_validF2),.out(instrD));
    flopstrc #(1) flopIsdelayD(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),
        .in(is_in_delayslot_iF),.out(is_in_delayslot_iD));
    //-----------------------DecodeFlop----------------------------------
    wire[5:0] functD;
	aludec ad(functD,aluopD,alucontrolD);
	maindec md(instrD,
		//output
        sign_exD , regdstD, is_immD , regwriteD , mem_readD , mem_writeD , memtoregD,
		hilotoregD , riD, breakD , syscallD , eretD , cp0_writeD , cp0_to_regD,
        mfhiD , mfloD , is_mfcD,  aluopD, functD , branch_judge_controlD );
    
    //扩展立即数
    signext signex(sign_exD,instrD[15:0],immD);
	//regfile，                             rs            rt
	regfile rf(clk,rst,stallW,regwriteW,instrD[25:21],instrD[20:16],writeregW,resultW,rd1D,rd2D);
    // 立即数左移2 + pc+4得到分支跳转地址   
    assign pc_branchD = {immD[29:0], 2'b00} + PcPlus4D;
    //选择writeback寄存器     rd             rt
    mux3 #(5) mux3_regdst(instrD[15:11],instrD[20:16],5'd31,regdstD,  writeregD);
    //前推至ID阶段                                                          todo shamt
    mux8 #(32) mux8_forward_1D(rd1D, resultW, resultM2, resultM, aluoutE, instrD[10:6], 32'b0, 32'b0, forward_1D, src_a1D);
    mux8 #(32) mux8_forward_2D(rd2D, resultW, resultM2, resultM, aluoutE, 32'b0, 32'b0, 32'b0, forward_2D, src_b1D);
    //choose imm
    mux2 #(32) mux2_imm(src_b1D, immD ,is_immD,  src_bD);
    //choose jump
    mux2 #(32) mux2_jump(src_a1D,PcPlus4F2, jumpD | branchD,src_aD);
	// BranchPredict
    BranchPredict branch_predict(
        .clk(clk), .rst(rst),
        .flushD(flushD),.stallD(stallD),.instrD(instrD),
        
        .immD(immD),
        .pcF(PC_IF1),
        .pcM(pcM),
        .branchE(branchM),
        .actual_takeE(actual_takeM),

        .branchD(branchD),
        .pred_takeD(pred_takeD)
    );
    // jump, assign Logic
    jump_control jump_control(
        .instrD(instrD),
        .PcPlus4D(PcPlus4D),
        .rd1D(rd1D),
        .regwriteE(regwriteE), .writeregE(writeregE), 
        .regwriteM(regwriteM), .writeregM(writeregM),
        .regwriteM2(regwriteM2), .writeregM2(writeregM2),
        .regwriteW(regwriteW), .writeregW(writeregW),

        .jumpD(jumpD),                      //是jump类指令(j, jr)
        .jump_conflictD(jump_conflictD),    //jr rs寄存器发生冲突
        .pc_jumpD(pc_jumpD)                 //D阶段最终跳转地址
    );
	//----------------------------------Execute------------------------------------
    flopstrc #(32) flopPcE(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(PcD),.out(pcE));
    flopstrc #(32) flopInstE(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(instrD),.out(instrE));
    flopstrc #(32) flopSrca1E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(src_a1D),.out(src_a1E));
    flopstrc #(32) flopSrcb1E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(src_b1D),.out(src_b1E));
    flopstrc #(32) flopSrcaE(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(src_aD),.out(src_aE));
    flopstrc #(32) flopSrcbE(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(src_bD),.out(src_bE));
    flopstrc #(32) flopPcplus4E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(PcPlus4D),.out(pcplus4E));
    flopstrc #(32) flopPcbranchE(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(pc_branchD),.out(pc_branchE));
    flopstrc #(8) flopSign1E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),
        .in({branchD,pred_takeD,is_in_delayslot_iD,jump_conflictD,regwriteD,riD,breakD,hilotoregD}),
        .out({branchE,pred_takeE,is_in_delayslot_iE,jump_conflictE,regwriteE,riE,breakE,hilotoregE}));
    flopstrc #(10) flopSign2E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),
        .in({memtoregD,mem_writeD,mem_readD,syscallD,eretD,cp0_to_regD,is_mfcD,mfloD,mfhiD,cp0_writeD}),
        .out({memtoregE,mem_writeE,mem_readE,syscallE,eretE,cp0_to_regE,is_mfcE,mfloE,mfhiE,cp0_writeE}));
    flopstrc #(18) flopSign3E(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),
        .in({alucontrolD,branch_judge_controlD,writeregD,regdstD}),
        .out({alucontrolE,branch_judge_controlE,writeregE,regdstE}));
    //-----------------------ExFlop---------------------
	//ALU
    alu aluitem(
        //input
        .clk(clk),.rst(rst),.stallE(stallE),.flushE(flushE),
        .src_aE(src_aE), .src_bE(src_bE),
        .alucontrolE(alucontrolE),.sa(instrE[10:6]),.msbd(instrE[15:11]),
        .mfhiE(mfhiE), .mfloE(mfloE), .flush_exceptionM(flush_exceptionM),
        //output
        .alustallE(alu_stallE),
        .aluoutE(aluoutE) , .overflowE(overflowE)
    );
    
	//在execute阶段得到真实branch跳转情况
    branch_check branch_check(
        .branch_judge_controlE(branch_judge_controlE),
        .rs_valueE(src_a1E),
        .rt_valueE(src_b1E),
        .actual_takeE(actual_takeE)
    );
    
    assign pc_jumpE =src_a1E; //jr指令 跳转到rs
    assign flush_jump_conflictE = jump_conflictE;
	//-------------------------------------Memory----------------------------------------
	flopstrc #(32) flopPcM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(pcE),.out(pcM));
	flopstrc #(32) flopAluM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(aluoutE),.out(aluoutM));
	flopstrc #(32) flopRtvalueM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(src_b1E),.out(src_b1M));
	flopstrc #(32) flopInstrM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(instrE),.out(instrM));
	flopstrc #(32) flopPcbM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(pc_branchE),.out(pc_branchM));
    flopstrc #(9) flopSign1M(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),
        .in({regwriteE,pred_takeE,branchE,is_in_delayslot_iE,actual_takeE,mem_readE,mem_writeE,memtoregE,breakE}),
        .out({regwriteM,pred_takeM,branchM,is_in_delayslot_iM,actual_takeM,mem_readM,mem_writeM,memtoregM,breakM}));
    flopstrc #(8) flopSign2M(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),
        .in({riE,syscallE,eretE,cp0_writeE,cp0_to_regE,is_mfcE,breakE,hilotoregE}),
        .out({riM,syscallM,eretM,cp0_writeM,cp0_to_regM,is_mfcM,breakM,hilotoregM}));
    flopstrc #(6) flopWriteregM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),
        .in({writeregE,overflowE}),.out({writeregM,overflowM}));
    //----------------------MemoryFlop------------------------
    assign mem_enM = (mem_readM  |  mem_writeM) & ~flush_exceptionM;; //意外刷新时需要
    // Assign Logical
    mem_control mem_control(
        .instrM(instrM), .instrM2(instrM2), .addressM(aluoutM), .addressM2(aluoutM2),
    
        .data_wdataM(src_b1M),    //原始的wdata
        .rt_valueM2(src_b1M2),
        .writedataM(writedataM),    //新的wdata
        .mem_write_selectM(mem_write_selectM),
        .data_addrM(mem_addrM),
        .mem_rdataM2(mem_rdataM2), .data_rdataM2(result_rdataM2),

        .addr_error_sw(addrErrorSwM), .addr_error_lw(addrErrorLwM)  
    );

    
    //后两位不为0
    assign pcErrorM = |(pcM[1:0] ^ 2'b00);  
    //在aluoutM, hilo_outM, cp0_outM2 中选择写入寄存器的数据 Todo
    mux2 #(32) mux2_memtoregM(aluoutM, cp0_outM2, is_mfcM, resultM);
     //异常处理
    exception exception(
        .rst(rst),.ext_int(ext_int),
        //异常信号
        .ri(riM), .break_exception(breakM), .syscall(syscallM), .overflow(overflowM), 
        .addrErrorSw(addrErrorSwM), .addrErrorLw(addrErrorLwM), .pcError(pcErrorM), .eretM(eretM),
        //异常寄存器
        .cp0_status(cp0_statusM2), .cp0_cause(cp0_causeM2), .cp0_epc(cp0_epcM2),
        //记录出错地址
        .pcM(pcM),.aluoutM(aluoutM),
        //输出异常处理信号
        .except_type(except_typeM),.flush_exception(flush_exceptionM),.pc_exception(pc_exceptionM),
        .pc_trap(pc_trapM),.badvaddrM(badvaddrM)
    );
     // cp0 todo 
    cp0_reg cp0(
        .clk(clk) , .rst(rst),
        .we_i(cp0_writeM) , .i_cache_stall(i_cache_stall),
        .waddr_i(instrM[15:11]) , .raddr_i(instrM[15:11]),
        .data_i(src_b1M) , .int_i(ext_int),
        
        .data_o(cp0_outM2),

        .excepttype_i(except_typeM) , .current_inst_addr_i(pcM),
        .is_in_delayslot_i(is_in_delayslot_iM) , .bad_addr_i(badvaddrM),

        .status_o(cp0_statusM2) , .cause_o(cp0_causeM2) , .epc_o(cp0_epcM2)
    );
    //分支预测结果
    assign pre_right = ~(pred_takeM ^ actual_takeM); 
    assign flush_pred_failedM = ~pre_right;
	//-------------------------------------Memory2-------------------------------------------------
    wire is_mfcM2; // for debug
    // todo M2 flop
	flopstrc #(8) flopWriregM2(.clk(clk),.rst(rst),.stall(stallM2),.flush(flushM2),
            .in({writeregM, regwriteM ,memtoregM,is_mfcM}),
            .out({writeregM2, regwriteM2, memtoregM2,is_mfcM2}));
	flopstrc #(32) flopAluoutM2(.clk(clk),.rst(rst),.stall(stallM2),.flush(flushM2),.in(aluoutM),.out(aluoutM2));
	flopstrc #(32) flopResM2(.clk(clk),.rst(rst),.stall(stallM2),.flush(flushM2),.in(resultM),.out(resultori_M2));
	flopstrc #(32) flopPcM2(.clk(clk),.rst(rst),.stall(stallM2),.flush(flushM2),.in(pcM),.out(pcM2));
	flopstrc #(32) flopInstrM2(.clk(clk),.rst(rst),.stall(stallM2),.flush(flushM2),.in(instrM),.out(instrM2));
    flopstrc #(32) flopRtvalueM2(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(src_b1M),.out(src_b1M2));
	//------------------Memory2_Flop--------------------------
    mux2 #(32) mux2_memtoreg(resultori_M2,result_rdataM2, memtoregM2,resultM2);
	//-------------------------------------Write_Back-------------------------------------------------
    wire is_mfcW;
    wire [31:0] instrW; // for debug
	flopstrc #(7) flopWriregW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),
            .in({writeregM2,regwriteM2,is_mfcM2}),
            .out({writeregW,regwriteW,is_mfcW}));
	flopstrc #(32) flopInstrW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(instrM2),.out(instrW));
	flopstrc #(32) flopPcW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(pcM2),.out(pcW));
	flopstrc #(32) flopAluoutW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(aluoutM2),.out(aluoutW));
	flopstrc #(32) flopResW(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(resultM2),.out(resultW));
	//------------------Write_Back_Flop--------------------------

	//hazard detection
    wire Blank_SL = (~|(aluoutE[31:2] ^ aluoutM[31:2])) & mem_writeM &  mem_readE;
	hazard hazard0(
        .i_cache_stall(i_cache_stall),
        .d_cache_stall(d_cache_stall),
        .alu_stallE(alu_stallE),

        .jumpD                  (jumpD),
        .flush_jump_conflictE   (flush_jump_conflictE),
        .flush_pred_failedM     (flush_pred_failedM),
        .flush_exceptionM       (flush_exceptionM),

        .branchD(branchD), .branchM(branchM), .pre_right(pre_right), .pred_takeD(pred_takeD),

        .rsD(instrD[25:21]),
        .rtD(instrD[20:16]),
        .is_mfcE(is_mfcE),
        .hilotoregE(hilotoregE),
        .regwriteE(regwriteE),
        .regwriteM(regwriteM),
        .regwriteM2(regwriteM2),
        .regwriteW(regwriteW),
        .writeregE(writeregE),
        .writeregM(writeregM),
        .writeregM2(writeregM2),
        .writeregW(writeregW),
        .mem_readE(mem_readE),
        .mem_readM(mem_readM),
        
        .Blank_SL(Blank_SL),
        .stallF(stallF), .stallF2(stallF2), .stallD(stallD), .stallE(stallE), .stallM(stallM), .stallM2(stallM2), .stallW(stallW),
        .flushF(flushF), .flushF2(flushF2), .flushD(flushD), .flushE(flushE), .flushM(flushM), .flushM2(flushM2), .flushW(flushW),
        .longest_stall(longest_stall), .stallDblank(stallDblank),
        .forward_1D(forward_1D), .forward_2D(forward_2D)
    );
	
endmodule
