module datapath(

	input wire clk,rst,
	
	input wire  [5 :0] ext_int, //中断
    
    //inst
    output wire [31:0] PC_IF1,  //Inst addr
    output wire        inst_enF, 
    input wire  [31:0] inst1_F2,  inst2_F2, 
    input wire         i_cache_stall,

    //data
    output wire mem_enM,                    
    output wire [31:0] mem_addrM,     // Write Address
    input  wire [31:0] mem_rdataM2,    // Read Data
    output wire [3 :0] mem_write_selectM,      // Write Enable
    output wire [31:0] writedataM,    // Write Data
    input wire         d_cache_stall,

    output wire        alu_stallE, icache_Ctl, 
	//debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
    );
	
	//--------InstFetch1 stage----------
	wire [31:0] PcPlus4F, PcPlus8F, PcPlus12F;    //pc
    
    wire pc_errorF;  // pc错误

    //--------InstFetch2 stage----------
	wire [31:0] PcPlus4F2, PcPlus8F2, PcPlus12F2;    //pc
    wire [31:0] PcF2;    //pc
    wire        delayslot_masterF2, delayslot_slaveF2; // 此时的D阶段（即上一条指令）是否为跳转指令
	//----------decode stage---------
    ctrl_sign   dec_sign1D, dec_sign2D;
    wire        master_only_oneD, slave_only_oneD;
	wire [31:0] instr1D;  //指令
    wire [31:0] PcD, PcPlus4D, PcPlus8D, PcPlus12D;  //pc
    wire [31:0] src1_a1D, src1_b1D,src1_aD, src1_bD; //alu输入（操作数
    wire [31:0] src2_a1D, src2_b1D,src2_aD, src2_bD; //alu输入（操作数
    wire [31:0] Mrd1D, Mrd2D, immd1D, pc_branch1D, pc_jump1D;  //寄存器读出数据 立即数 pc分支 跳转
    wire [31:0] Srd1D, Srd2D, immd2D, pc_branch2D, pc_jump2D;  //寄存器读出数据 立即数 pc分支 跳转
    wire        pred_takeD, branch1D, branch2D, jump1D, jump2D;  //立即数扩展 分支预测 branch jump信号
    wire        pred_failed_masterE, pred_failed_slaveE;  //分支预测失败

    wire        delayslot_masterD, delayslot_slaveD;//指令是否在延迟槽
    wire [2:0]  forward1_1D, forward2_1D;
    wire [2:0]  forward1_2D, forward2_2D;
	//-------execute stage----------
    ctrl_sign   dec_sign1E, dec_sign2E;
	wire [31:0] pcE, pcplus4E, PcPlus8E, PcPlus12E; //pc pc+4 寄存器号 写内存 立即数
    wire        pred_takeE;  //分支预测

    wire [31:0] src1_a1E, src1_b1E; //alu输入（操作数
    wire [31:0] src1_aE, src1_bE; //alu输入（操作数
    wire [31:0] aluout1E; //alu输出
    wire        branchE; //分支信号
    wire [31:0] pc_branch1E;  //分支跳转pc

    wire [31:0] instrE;
    wire [31:0] pc_jumpE;  //jump pc
    // wire        alu_stallE;  //alu暂停
    wire        actual_takeE;  //分支预测 实际结果
    wire [1:0]  hilo_selectE;  //高位1表示是mhl指令，0表示是乘除法
                              //低位1表示是用hi，0表示用lo
 // 异常处理信号
    wire        delayslot_masterE; //是否处于延迟槽
    wire        overflowE; //溢出
    wire        trapE; //自陷
	
	//----------mem stage--------
    ctrl_sign   dec_sign1M, dec_sign2M;
	wire [31:0] pcM;  // pc
    wire [31:0] aluout1M; //alu输出
    wire [4:0] 	writeregM; //写寄存器号
    wire [31:0] instrM;  //指令
    wire        mem_readM; //读内存
    wire        mem_writeM; //写内存
    wire        regwriteM;  //寄存器写
    wire        memtoregM;  //写回寄存器选择信号
    wire [31:0] result1M, result2M;  // mem out
    wire        actual_takeM;  //分支预测 真实结果
    wire        pre_right;  // 预测正确
    wire        pred_takeM; // 预测
    wire        branchM; // 分支信号
    wire [31:0] pc_branch1M; //分支跳转地址

    wire [31:0] hilo_outM;  //hilo输出
	wire		is_mfcM;

    wire [31:0] src1_b1M;
    //异常处理信号 exception
    wire        overflowM;  //算数溢出
    wire        trapM;  //自陷指令
    wire        addrErrorLwM, addrErrorSwM; //访存指令异常
    wire        pcErrorM;  //pc异常

	// cp0	
    wire [31:0] except_typeM;  // 异常类型
    wire        flush_exception_masterM;  // 发生异常时需要刷新流水线
    wire [31:0] pc_exceptionM; //异常处理的地址0xbfc0_0380，若为eret指令 则为返回地址
    wire        pc_trapM; // 发生异常时pc特殊处理
    wire [31:0] badvaddrM;
    wire        delayslot_masterM;
    wire        cp0_to_regM;
    wire        cp0_writeM;
    //------writeback stage----------
    ctrl_sign   dec_sign1M2, dec_sign2M2;
    wire [31:0] result1_rdataM2, result2_rdataM2;
	wire [31:0] result1_cdataM2, result2_cdataM2;
	wire [31:0] result1M2, result2M2;
    wire [31:0] aluout1M2, aluout2M2;
    wire [31:0] pcM2;
    wire [31:0] instrM2;
    wire [31:0] cp0_statusM2, cp0_causeM2, cp0_epcM2, cp0_outM2;
    wire [31:0] src1_b1M2;
	//------writeback stage----------
    ctrl_sign   dec_sign1W, dec_sign2W;
	wire regwriteW;
	wire [31:0] result1W, result2W;
    wire [31:0] aluout1W, aluout2W;
    wire [31:0] pcW;
    //------stall sign---------------
    wire stallF, stallF2, stall_masterD, stall_masterE, stall_masterM, stall_masterM2, stall_masterW ,stallDblank;
    wire stall_slaveD, stall_slaveE, stall_slaveM, stall_slaveM2, stall_slaveW;

    wire flushF, flushF2, flush_masterD, flush_masterE, flush_masterM, flush_masterM2, flushW;
    wire flush_slaveD, flush_slaveE, flush_slaveM, flush_slaveM2;
//------------------------------------------Data------------------------------------------
	//--------------------debug---------------------
    assign debug_wb_pc          = pcW;
    assign debug_wb_rf_wen      = {4{regwriteW & ~stall_masterW }};
    assign debug_wb_rf_wnum     = writeregW;
    assign debug_wb_rf_wdata    = result1W;
    // Todo : jal wrong
//------------------------------------------Hazard-------------------------------------------
//hazard detection
    wire Blank_SL = (~|(aluout1M[31:2] ^ aluout1M2[31:2])) & mem_writeM2 &  mem_readM;
	hazard hazard0(
        .i_cache_stall(i_cache_stall),
        .d_cache_stall(d_cache_stall),
        .alu_stallE(alu_stallE),
        .master_only_oneD(master_only_oneD), slave_only_oneD(slave_only_oneD), 

        .jump1D (jump1D), .jump2D (jump2D), .branch1D(branch1D), branch2D(branch2D),
        .pred_failed_masterE(pred_failed_masterE), .pred_failed_slaveE(pred_failed_slaveE),
        .flush_exception_masterM(flush_exception_masterM), .flush_exception_slaveM(flush_exception_slaveM),

        .dec_sign1D(dec_sign1D), .dec_sign2D(dec_sign2D), 
        .dec_sign1E(dec_sign1E), .dec_sign2E(dec_sign2E), 
        .dec_sign1M(dec_sign1M), .dec_sign2M(dec_sign2M), 
        .dec_sign1M2(dec_sign1M2), .dec_sign2M2(dec_sign2M2), 
        .dec_sign1W(dec_sign1W), .dec_sign2W(dec_sign2W), 
        .pre_right(pre_right), .pred_takeD(pred_takeD),

        .rs1D(instr1D[25:21]), .rt1D(instr1D[20:16]),
        .rs2D(instr2D[25:21]), .rt2D(instr2D[20:16]),
        
        .Blank_SL(Blank_SL),
        // Master
        .stallF(stallF), .stallF2(stallF2), .stall_masterD(stall_masterD), .stall_masterE(stall_masterE), 
        .stall_masterM(stall_masterM), .stall_masterM2(stall_masterM2), .stall_masterW(stall_masterW),
        // Slave
        .stall_slaveD(stall_slaveD), .stall_slaveE(stall_slaveE), 
        .stall_slaveM(stall_slaveM), .stall_slaveM2(stall_slaveM2), .stall_slaveW(stall_slaveW),
        
        // Master
        .flushF(flushF), .flushF2(flushF2), .flush_masterD(flush_masterD), .flush_masterE(flush_masterE), 
        .flush_masterM(flush_masterM), .flush_masterM2(flush_masterM2), .flushW(flushW),
        // Slave
        .flush_slaveD(flush_slaveD), .flush_slaveE(flush_slaveE), .flush_slaveM(flush_slaveM), .flush_slaveM2(flush_slaveM2),

        // ctrl
        .stallDblank(stallDblank), .icache_Ctl(icache_Ctl), 
        .forward1_1D(forward1_1D), .forward1_2D(forward1_2D), .forward2_1D(forward2_1D), .forward2_2D(forward2_2D)
    );

    //--------------------------------------Fetch------------------------------------------------
    
    assign inst_enF = ~flush_exception_masterM & ~pc_errorF & ~pred_failed_masterE & ~stallDblank;
    // pc+4
    assign PcPlus4F = PC_IF1 + 4;
    assign PcPlus8F = PC_IF1 + 8;
    assign PcPlus12F = PC_IF1 + 12;
    assign pc_errorF = (~|(PC_IF1[1:0] ^ 2'b0)) ? 1'b0 : 1'b1; 
    // pc reg
    pc_reg pc(
        .clk(clk), .rst(rst), .stallF(stallF),
        .branch1D(branch1D), .branchM(branchM), .pre_right(pre_right), .actual_takeM(actual_takeM),
        .pred_takeD(pred_takeD), .pc_trapM(pc_trapM), .jump1D(jump1D),

        .pc_exceptionM(pc_exceptionM), .pcplus4E(pcplus4E), .pc_branch1M(pc_branch1M),
        .pc_jump1D(pc_jump1D), .pc_branch1D(pc_branch1D), .PcPlus4F(PcPlus4F), .PcPlus8F(PcPlus8F), 

        .pc(PC_IF1)
    );
    
	//----------------------------------------InstFetch2------------------------------------------------
    wire inst_enF2;
    wire [31:0] inst1_validF2, inst2_validF2;
    flopstrc #(32) flopPcplus4F2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PcPlus4F),.out(PcPlus4F2));
    flopstrc #(32) flopPcplus8F2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PcPlus8F),.out(PcPlus8F2));
    flopstrc #(32) flopPcF2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PC_IF1),.out(PcF2));
    flopstrc #(1) flopInstEnF2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(inst_enF),.out(inst_enF2));
    assign inst1_validF2 = {32{inst_enF2}}&inst1_F2;  // Discard Not Valid
    assign inst2_validF2 = {32{inst_enF2}}&inst2_F2;  // Discard Not Valid
    assign delayslot_masterF2 = branch2D | jump2D; //通过前一条指令，判断是否是延迟槽
    //-----------------------InstFetch2Flop------------------------------


	//----------------------------------------Decode------------------------------------------------
    flopstrc #(32) flopPcplusD(.clk(clk),.rst(rst),.stall(stall_masterD),.flush(flush_masterD),.in(PcPlus4F2),.out(PcPlus4D));
    flopstrc #(32) flopPcplus8D(.clk(clk),.rst(rst),.stall(stall_masterD),.flush(flush_masterD),.in(PcPlus8F2),.out(PcPlus8D));
    flopstrc #(32) flopPcD(.clk(clk),.rst(rst),.stall(stall_masterD),.flush(flush_masterD),.in(PcF2),.out(PcD));
    flopstrc #(32) flopInst1D(.clk(clk),.rst(rst),.stall(stall_masterD),.flush(flush_masterD),.in(inst1_validF2),.out(instr1D));
    flopstrc #(32) flopInst2D(.clk(clk),.rst(rst),.stall(stall_masterD),.flush(flush_masterD),.in(inst2_validF2),.out(instr2D));
    flopstrc #(1) flopIsdelayD(.clk(clk),.rst(rst),.stall(stall_masterD),.flush(flush_masterD),
        .in(delayslot_masterF2),.out(delayslot_masterD));
    //-----------------------DecodeFlop----------------------------------
	maindec main_dec1(.instrD(instr1D),.dec_sign(dec_sign1D), .only_oneD_inst(master_only_oneD));
	maindec main_dec2(.instrD(instr2D),.dec_sign(dec_sign2D), .only_oneD_inst(slave_only_oneD));

    //扩展立即数
    signext signex1(dec_sign1D.sign_ex,instr1D[15:0],immd1D);
    signext signex2(dec_sign2D.sign_ex,instr2D[15:0],immd2D);
	//regfile，                             we3                we4
	regfile rf(clk,rst,stall_masterW,dec_sign1D.regwrite, dec_sign2D.regwrite
            instr1D[25:21], instr1D[20:16], instr2D[25:21], instr2D[20:16],
            dec_sign1W.writereg, dec_sign2W.writereg, result1W, result2W
            Mrd1D, Mrd2D, Srd1D, Srd2D);
    // 立即数左移2 + pc+4得到分支跳转地址   
    assign pc_branch1D = {immd1D[29:0], 2'b00} + PcPlus4D; 
    assign pc_branch2D = {immd2D[29:0], 2'b00} + PcPlus8D; 
    assign delayslot_slaveD = branch1D | jump1D; //通过前一条指令，判断是否是延迟槽
    //选择writeback寄存器     rd             rt
    mux3 #(5) mux3_regdst1(instr1D[15:11], instr1D[20:16], 5'd31, dec_sign1D.regdst, dec_sign1D.writereg);
    mux3 #(5) mux3_regdst2(instr2D[15:11], instr2D[20:16], 5'd31, dec_sign2D.regdst, dec_sign2D.writereg);
    // Forward 1
    mux8 #(32) mux8_forward1_1D(Mrd1D, result1W, result1M2, result1M, aluout1E, instr1D[10:6], 32'b0, 32'b0, forward1_1D, src1_a1D);
    mux8 #(32) mux8_forward1_2D(Mrd2D, result1W, result1M2, result1M, aluout1E, 32'b0, 32'b0, 32'b0, forward1_2D, src1_b1D);
    // Forward 2
    mux8 #(32) mux8_forward2_1D(Srd1D, result2W, result2M2, result2M, aluout2E, instr2D[10:6], 32'b0, 32'b0, forward2_1D, src2_a1D);
    mux8 #(32) mux8_forward2_2D(Srd2D, result2W, result2M2, result2M, aluout2E, 32'b0, 32'b0, 32'b0, forward2_2D, src2_b1D);
    //choose immd1
    mux2 #(32) mux2_immd1(src1_b1D, immd1D ,is_immd1D,  src1_bD);
    mux2 #(32) mux2_immd1(src2_b1D, immd2D ,is_immd2D,  src2_bD);
    //choose jump
    mux2 #(32) mux2_jump(src1_a1D,PcPlus4F2, jump1D | branch1D,src1_aD);
    mux2 #(32) mux2_jump(src2_a1D,PcPlus4F2, jump1D | branch1D,src2_aD);
	// BranchPredict
    BranchPredict branch_predict(
        .clk(clk), .rst(rst),
        .flush_masterD(flush_masterD),.stall_masterD(stall_masterD),.instrD(instrD),
        
        .immd1D(immd1D),
        .PcF2(PcF2),
        .pcE(pcE),
        .branchE(branchE),
        .actual_takeE(actual_takeE),

        .branch1D(branch1D),
        .pred_takeD(pred_takeD)
    );
    // jump, assign Logic
    jump_control jump_control(
        .instr1D(instr1D),
        .PcPlus4D(PcPlus4D),
        .src1_a1D(src1_a1D),

        .jump1D(jump1D),                      //是jump类指令(j, jr)
        .pc_jump1D(pc_jump1D)                 //D阶段最终跳转地址
    );
	//----------------------------------Execute------------------------------------
    flopstrc #(32) flopPcE(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(PcD),.out(pcE));
    flopstrc #(32) flopInstE(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(instr1D),.out(instrE));
    flopstrc #(32) flopSrca1E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(src1_a1D),.out(src1_a1E));
    flopstrc #(32) flopSrcb1E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(src1_b1D),.out(src1_b1E));
    flopstrc #(32) flopSrcaE(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(src1_aD),.out(src1_aE));
    flopstrc #(32) flopSrcbE(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(src1_bD),.out(src1_bE));
    flopstrc #(32) flopPcplus4E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(PcPlus4D),.out(pcplus4E));
    flopstrc #(32) flopPcbranchE(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(pc_branch1D),.out(pc_branch1E));
    flopstrc #(8) flopSign1E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),
        .in({branch1D,pred_takeD,delayslot_masterD,regwriteD,riD,breakD,hilotoregD}),
        .out({branchE,pred_takeE,delayslot_masterE,regwriteE,riE,breakE,hilotoregE}));
    flopstrc #(11) flopSign2E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),
        .in({memtoregD,mem_writeD,mem_readD,syscallD,eretD,cp0_to_regD,is_mfcD,mfloD,mfhiD,cp0_writeD, DivMulEnD}),
        .out({memtoregE,mem_writeE,mem_readE,syscallE,eretE,cp0_to_regE,is_mfcE,mfloE,mfhiE,cp0_writeE, DivMulEnE}));
    flopstrc #(18) flopSign3E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),
        .in({alucontrolD,branch_judge_controlD,writeregD,regdstD}),
        .out({alucontrolE,branch_judge_controlE,writeregE,regdstE}));
    //-----------------------ExFlop---------------------
	//ALU
    alu aluitem(
        //input
        .clk(clk),.rst(rst),.stall_masterE(stall_masterE),.flush_masterE(flush_masterE),
        .src1_aE(src1_aE), .src1_bE(src1_bE),
        .alucontrolE(alucontrolE),.sa(instrE[10:6]),.msbd(instrE[15:11]),
        .mfhiE(mfhiE), .mfloE(mfloE), .flush_exception_masterM(flush_exception_masterM), .DivMulEnE(DivMulEnE), 
        //output
        .alustallE(alu_stallE),
        .aluout1E(aluout1E) , .overflowE(overflowE), .trapE(trapE)
    );
    
	//在execute阶段得到真实branch跳转情况
    branch_check branch_check(
        .branch_judge_controlE(branch_judge_controlE),
        .rs_valueE(src1_a1E),
        .rt_valueE(src1_b1E),
        .actual_takeE(actual_takeE)
    );
    
    assign pc_jumpE =src1_a1E; //jr指令 跳转到rs
	//-------------------------------------Memory----------------------------------------
	flopstrc #(32) flopPcM(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(pcE),.out(pcM));
	flopstrc #(32) flopAluM(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(aluout1E),.out(aluout1M));
	flopstrc #(32) flopRtvalueM(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(src1_b1E),.out(src1_b1M));
	flopstrc #(32) flopInstrM(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(instrE),.out(instrM));
	flopstrc #(32) flopPcbM(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(pc_branch1E),.out(pc_branch1M));
    flopstrc #(9) flopSign1M(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),
        .in({regwriteE,pred_takeE,branchE,delayslot_masterE,actual_takeE,mem_readE,mem_writeE,memtoregE,breakE}),
        .out({regwriteM,pred_takeM,branchM,delayslot_masterM,actual_takeM,mem_readM,mem_writeM,memtoregM,breakM}));
    flopstrc #(7) flopSign2M(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),
        .in({riE,syscallE,eretE,cp0_writeE,cp0_to_regE,is_mfcE,hilotoregE}),
        .out({riM,syscallM,eretM,cp0_writeM,cp0_to_regM,is_mfcM,hilotoregM}));
    flopstrc #(6) flopWriteregM(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),
        .in({writeregE,overflowE}),.out({writeregM,overflowM}));
    // 可合并
    flopstrc #(1) flopTrapM(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(trapE),.out(trapM));
    //----------------------MemoryFlop------------------------
    assign mem_enM = (mem_readM  |  mem_writeM) & ~flush_exception_masterM;; //意外刷新时需要
    // Assign Logical
    mem_control mem_control(
        .instrM(instrM), .instrM2(instrM2), .addressM(aluout1M), .addressM2(aluout1M2),
    
        .data_wdataM(src1_b1M),    //原始的wdata
        .rt_valueM2(src1_b1M2),
        .writedataM(writedataM),    //新的wdata
        .mem_write_selectM(mem_write_selectM),
        .data_addrM(mem_addrM),
        .mem_rdataM2(mem_rdataM2), .data_rdataM2(result1_rdataM2),

        .addr_error_sw(addrErrorSwM), .addr_error_lw(addrErrorLwM)  
    );

    
    //后两位不为0
    assign pcErrorM = |(pcM[1:0] ^ 2'b00);  
    //在aluout1M, hilo_outM, cp0_outM2 中选择写入寄存器的数据 Todo
    mux2 #(32) mux2_memtoregM(aluout1M, cp0_outM2, is_mfcM, result1M);
     //异常处理
    exception exception(
        .rst(rst),.ext_int(ext_int),
        //异常信号
        .ri(riM), .break_exception(breakM), .syscall(syscallM), .overflow(overflowM), 
        .addrErrorSw(addrErrorSwM), .addrErrorLw(addrErrorLwM), .pcError(pcErrorM), .eretM(eretM),
        //异常寄存器
        .cp0_status(cp0_statusM2), .cp0_cause(cp0_causeM2), .cp0_epc(cp0_epcM2),
        //记录出错地址
        .pcM(pcM),.aluout1M(aluout1M),
        //输出异常处理信号
        .except_type(except_typeM),.flush_exception_master(flush_exception_masterM),.pc_exception(pc_exceptionM),
        .pc_trap(pc_trapM),.badvaddrM(badvaddrM)
    );
     // cp0 todo 
    cp0_reg cp0(
        .clk(clk) , .rst(rst),
        .i_cache_stall(i_cache_stall), .we_i(cp0_writeM) ,
        .waddr_i(instrM[15:11]) , .raddr_i(instrM[15:11]),
        .data_i(src1_b1M) , .int_i(ext_int),
        .excepttype_i(except_typeM) , .current_inst_addr_i(pcM),
        .delayslot_master(delayslot_masterM) , .bad_addr_i(badvaddrM),
        .status_o(cp0_statusM2) , .cause_o(cp0_causeM2) ,
        .epc_o(cp0_epcM2), .data_o(cp0_outM2)
    );
    //分支预测结果
    assign pre_right = ~(pred_takeM ^ actual_takeM); 
    assign pred_failed_masterE = ~pre_right;
	//-------------------------------------Memory2-------------------------------------------------
    wire is_mfcM2, mem_writeM2; // for debug
    // todo M2 flop
	flopstrc #(9) flopWriregM2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),
            .in({writeregM, regwriteM ,memtoregM, mem_writeM, is_mfcM}),
            .out({writeregM2, regwriteM2, memtoregM2, mem_writeM2, is_mfcM2}));
	flopstrc #(32) flopaluout1M2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in(aluout1M),.out(aluout1M2));
	flopstrc #(32) flopResM2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in(result1M),.out(result1_cdataM2));
	flopstrc #(32) flopPcM2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in(pcM),.out(pcM2));
	flopstrc #(32) flopInstrM2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in(instrM),.out(instrM2));
    flopstrc #(32) flopRtvalueM2(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(src1_b1M),.out(src1_b1M2));
	//------------------Memory2_Flop--------------------------
    mux2 #(32) mux2_memtoreg(result1_cdataM2,result1_rdataM2, memtoregM2,result1M2);
	//-------------------------------------Write_Back-------------------------------------------------
    wire is_mfcW;
    wire [31:0] instrW; // for debug
	flopstrc #(7) flopWriregW(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),
            .in({writeregM2,regwriteM2,is_mfcM2}),
            .out({writeregW,regwriteW,is_mfcW}));
	flopstrc #(32) flopInstrW(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),.in(instrM2),.out(instrW));
	flopstrc #(32) flopPcW(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),.in(pcM2),.out(pcW));
	flopstrc #(32) flopaluout1W(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),.in(aluout1M2),.out(aluout1W));
	flopstrc #(32) flopResW(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),.in(result1M2),.out(result1W));
	//------------------Write_Back_Flop--------------------------
	
endmodule
