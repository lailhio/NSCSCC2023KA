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
    output wire [31:0] virtual_data_addrM,     // Write Address
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
    wire [31:0] PcFlopF;
    
    wire pc_errorF;  // pc错误

    //--------InstFetch2 stage----------
	wire [31:0] PcPlus4F2, PcPlus8F2, PcPlus12F2;    //pc
    wire [31:0] PcF2;    //pc
    wire        delayslot_masterF2, delayslot_slaveF2; // 此时的D阶段（即上一条指令）是否为跳转指令
    wire pc_errorF2;
	//----------decode stage---------
    wire pc_errorD;
    ctrl_sign   dec_sign1D, dec_sign2D;
    wire        master_only_oneD, slave_only_oneD;
	wire [31:0] instr1D, instr2D;  //指令
    wire [31:0] PcD, PcPlus4D, PcPlus8D, PcPlus12D;  //pc
    wire [31:0] src1_a1D, src1_b1D,src1_aD, src1_bD; //alu输入（操作数
    wire [31:0] src2_a1D, src2_b1D,src2_aD, src2_bD; //alu输入（操作数
    wire [31:0] Mrd1D, Mrd2D, immd1D, pc_branch1D, pc_jump1D;  //寄存器读出数据 立即数 pc分支 跳转
    wire [31:0] Srd1D, Srd2D, immd2D, pc_branch2D, pc_jump2D;  //寄存器读出数据 立即数 pc分支 跳转
    wire        pred_take1D, pred_take2D, branch1D, branch2D, jump1D, jump2D;  //立即数扩展 分支预测 branch jump信号

    wire        delayslot_masterD, delayslot_slaveD;//指令是否在延迟槽
    wire [3:0]  forward1_1D, forward2_1D;
    wire [3:0]  forward1_2D, forward2_2D;
	//-------execute stage----------
    wire pc_errorE;
    ctrl_sign   dec_sign1E, dec_sign2E;
	wire [31:0] pcE, PcPlus4E, PcPlus8E, PcPlus12E; //pc pc+4 寄存器号 写内存 立即数

    wire [31:0] src1_a1E, src1_b1E;
    wire [31:0] src2_a1E, src2_b1E;
    wire [31:0] src1_aE, src1_bE;
    wire [31:0] src2_aE, src2_bE;
    wire [31:0] aluout1E, aluout2E; //alu输出
    wire        branch1E, branch2E; //分支信号
    wire [31:0] pc_branch1E, pc_branch2E;  //分支跳转pc
    wire        pred_failedE, pred_failed_masterE, pred_failed_slaveE;  //分支预测失败
    wire        pred_take1E, pred_take2E;  //分支预测

    wire [31:0] instr1E, instr2E;
    // wire        alu_stallE;  //alu暂停
    wire        actual_take1E, actual_take2E;  //分支预测 实际结果
 // 异常处理信号
    wire        delayslot_masterE, delayslot_slaveE; //是否处于延迟槽
    wire        overflow1E, overflow2E; //溢出
    wire        trap1E ,trap2E; //自陷
	
	//----------mem stage--------
    wire pc_errorM;
    ctrl_sign   dec_sign1M, dec_sign2M;
	wire [31:0] pcM, PcPlus4M;  // pc
    wire [31:0] aluout1M, aluout2M; //alu输出
    wire [31:0] instr1M, instr2M;  //指令
    wire [31:0] result1M, result2M;  // mem out
    wire [31:0] pc_branch1M, pc_branch2M; //分支跳转地址
    wire [31:0] src1_b1M, src2_b1M;
    //异常处理信号 exception
    wire        overflow1M, overflow2M;  //算数溢出
    wire        trap1M, trap2M;  //自陷指令
    wire        addrErrorLw1M, addrErrorLw2M, addrErrorSw1M, addrErrorSw2M; //访存指令异常
    wire        pcErrorM;  //pc异常

	// cp0	
    wire [31:0] except_type1M, except_type2M;  // 异常类型
    wire        flush_exception_masterM, flush_exception_slaveM;  // 发生异常时需要刷新流水线
    wire [31:0] pc_exception1M, pc_exception2M; //异常处理的地址0xbfc0_0380，若为eret指令 则为返回地址
    wire        pc_trap1M, pc_trap2M; // 发生异常时pc特殊处理
    wire [31:0] badvaddr1M, badvaddr2M;
    wire        delayslot_masterM, delayslot_slaveM;
    //------Memory2 stage----------
    wire pc_errorM2;
    ctrl_sign   dec_sign1M2, dec_sign2M2;
    wire [31:0] result_rdataM2;
	wire [31:0] result1_cdataM2, result2_cdataM2;
	wire [31:0] result1M2, result2M2;
    wire [31:0] aluout1M2, aluout2M2;
    wire [31:0] pcM2, PcPlus4M2;
    wire [31:0] instr1M2, instr2M2;
    wire [31:0] cp0_statusM2, cp0_causeM2, cp0_epcM2, cp0_out1M2, cp0_out2M2;
	//------writeback stage----------
    wire pc_errorW;
    ctrl_sign   dec_sign1W, dec_sign2W;
	wire [31:0] result1W, result2W;
    wire [31:0] pcW, PcPlus4W;
    //------stall sign---------------
    wire stallF, stallF2, stall_masterD, stall_masterE, stall_masterM, stall_masterM2, stall_masterW ,stallDblank;
    wire stall_slaveD, stall_slaveE, stall_slaveM, stall_slaveM2, stall_slaveW;

    wire flushF, flushF2, flush_masterD, flush_masterE, flush_masterM, flush_masterM2, flushW;
    wire flush_slaveD, flush_slaveE, flush_slaveM, flush_slaveM2, fulsh_ex;
//------------------------------------------Data------------------------------------------
	//--------------------debug---------------------
    assign debug_wb_pc          = (clk) ? pcW : PcPlus4W;
    assign debug_wb_rf_wen      = (clk) ? {4{dec_sign1W.regwrite & ~stall_masterW}}: {4{dec_sign2W.regwrite & ~stall_slaveW}};
    assign debug_wb_rf_wnum     = (clk) ? dec_sign1W.writereg : dec_sign2W.writereg;
    assign debug_wb_rf_wdata    = (clk) ? result1W : result2W;
//------------------------------------------Hazard-------------------------------------------
//hazard detection
	hazard hazard0(
        .i_cache_stall(i_cache_stall),
        .d_cache_stall(d_cache_stall),
        .alu_stallE(alu_stallE),
        .master_only_oneD(master_only_oneD), .slave_only_oneD(slave_only_oneD), 

        .jump1D (jump1D), .jump2D (jump2D), 
        .pred_failed_masterE(pred_failed_masterE), .pred_failed_slaveE(pred_failed_slaveE),
        .flush_exception_masterM(flush_exception_masterM), .flush_exception_slaveM(flush_exception_slaveM),
        .fulsh_ex(fulsh_ex), 

        .dec_sign1D(dec_sign1D), .dec_sign2D(dec_sign2D), 
        .dec_sign1E(dec_sign1E), .dec_sign2E(dec_sign2E), 
        .dec_sign1M(dec_sign1M), .dec_sign2M(dec_sign2M), 
        .dec_sign1M2(dec_sign1M2), .dec_sign2M2(dec_sign2M2), 
        .dec_sign1W(dec_sign1W), .dec_sign2W(dec_sign2W), 
        .pred_take1D(pred_take1D), .pred_take2D(pred_take2D),

        .rs1D(instr1D[25:21]), .rt1D(instr1D[20:16]),
        .rs2D(instr2D[25:21]), .rt2D(instr2D[20:16]),
        
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
    
    assign inst_enF = ~(fulsh_ex) & ~pc_errorF & ~pred_failedE ;
    // pc+4
    assign PcFlopF = {PC_IF1[31:3], 3'b0};
    assign PcPlus4F = PcFlopF + 4;
    assign PcPlus8F = PcFlopF + 8;
    assign PcPlus12F = PcFlopF + 12;
    assign pc_errorF = |(PC_IF1[1:0] ^ 2'b0) ? 1'b1 : 1'b0; // Whatever Flush all
    // pc reg
    pc_reg pc(
        .clk(clk), .rst(rst), .stallF(stallF),
        .actual_take1E(actual_take1E), .actual_take2E(actual_take2E), .pred_take1E(pred_take1E), .pred_take2E(pred_take2E),
        .pred_take1D(pred_take1D), .pred_take2D(pred_take2D), .pc_trap1M(pc_trap1M),  .pc_trap2M(pc_trap2M), 
        .jump1D(jump1D), .jump2D(jump2D),

        .pc_exception1M(pc_exception1M), .pc_exception2M(pc_exception2M),
        .pc_branch1E(pc_branch1E), .pc_branch2E(pc_branch2E),
        .pc_jump1D(pc_jump1D), .pc_branch1D(pc_branch1D), .pc_jump2D(pc_jump2D), .pc_branch2D(pc_branch2D), 
        .PcPlus8F(PcPlus8F), .PcPlus8E(PcPlus8E), .PcPlus12E(PcPlus12E), 

        .pc(PC_IF1)
    );
    
	//----------------------------------------InstFetch2------------------------------------------------
    wire inst_enF2;
    wire [31:0] inst1_validF2, inst2_validF2;
    flopstrc #(32) flopPcF2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PcFlopF),.out(PcF2));
    flopstrc #(32) flopPcplus4F2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PcPlus4F),.out(PcPlus4F2));
    flopstrc #(32) flopPcplus8F2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PcPlus8F),.out(PcPlus8F2));
    flopstrc #(32) flopPcplus12F2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in(PcPlus12F),.out(PcPlus12F2));
    flopstrc #(2) flopInstEnF2(.clk(clk),.rst(rst),.stall(stallF2),.flush(flushF2),.in({inst_enF, pc_errorF}),.out({inst_enF2, pc_errorF2}));
    assign inst1_validF2 = {32{inst_enF2}} & inst1_F2;  // Discard Not Valid
    assign inst2_validF2 = {32{inst_enF2}} & inst2_F2;  // Discard Not Valid
    assign delayslot_masterF2 = branch2D | jump2D; //通过前一条指令，判断是否是延迟槽
    assign delayslot_slaveD = branch1D | jump1D; //通过前一条指令，判断是否是延迟槽
    //-----------------------InstFetch2Flop------------------------------


	//----------------------------------------Decode------------------------------------------------
    //-----------------------master---------------------------
    flopstrc #(32) flopPcD(.clk(clk),.rst(rst),.stall(stall_masterD),.flush(flush_masterD),.in(PcF2),.out(PcD));
    flopstrc #(32) flopPcplus8D(.clk(clk),.rst(rst),.stall(stall_masterD),.flush(flush_masterD),.in(PcPlus8F2),.out(PcPlus8D));
    flopstrc #(32) flopInst1D(.clk(clk),.rst(rst),.stall(stall_masterD),.flush(flush_masterD),.in(inst1_validF2),.out(instr1D));
    flopstrc #(2) flopIsdelayD(.clk(clk),.rst(rst),.stall(stall_masterD),.flush(flush_masterD),
        .in({delayslot_masterF2, pc_errorF2}),.out({delayslot_masterD, pc_errorD}));
    //-----------------------slave---------------------------
    flopstrc #(32) flopPcplus4D(.clk(clk),.rst(rst),.stall(stall_slaveD),.flush(flush_slaveD),.in(PcPlus4F2),.out(PcPlus4D));
    flopstrc #(32) flopPcplus12D(.clk(clk),.rst(rst),.stall(stall_slaveD),.flush(flush_slaveD),.in(PcPlus12F2),.out(PcPlus12D));
    flopstrc #(32) flopInst2D(.clk(clk),.rst(rst),.stall(stall_slaveD),.flush(flush_slaveD),.in(inst2_validF2),.out(instr2D));
    //-----------------------DecodeFlop----------------------------------
	maindec main_dec1(.instrD(instr1D), .instr2D(instr2D), .dec_sign(dec_sign1D), .only_oneD_inst(master_only_oneD));
	maindec main_dec2(.instrD(instr2D), .instr2D(instr1D), .dec_sign(dec_sign2D), .only_oneD_inst(slave_only_oneD));

    //扩展立即数
    signext signex1(dec_sign1D.sign_ex,instr1D[15:0],immd1D);
    signext signex2(dec_sign2D.sign_ex,instr2D[15:0],immd2D);
	//regfile，                             we3                we4
	regfile rf(clk,rst,stall_masterW,dec_sign1D.regwrite, dec_sign2D.regwrite,
            instr1D[25:21], instr1D[20:16], instr2D[25:21], instr2D[20:16],
            dec_sign1W.writereg, dec_sign2W.writereg, result1W, result2W,
            Mrd1D, Mrd2D, Srd1D, Srd2D);
    // 立即数左移2 + pc+4得到分支跳转地址   
    assign pc_branch1D = {immd1D[29:0], 2'b00} + PcPlus4D; 
    assign pc_branch2D = {immd2D[29:0], 2'b00} + PcPlus8D; 
    //选择writeback寄存器     rd             rt
    mux3 #(5) mux3_regdst1(instr1D[15:11], instr1D[20:16], 5'd31, dec_sign1D.regdst, dec_sign1D.writereg);
    mux3 #(5) mux3_regdst2(instr2D[15:11], instr2D[20:16], 5'd31, dec_sign2D.regdst, dec_sign2D.writereg);
    // Forward 1
    mux9 #(32) mux9_forward1_1D(Mrd1D, result1W, result1M2, result1M, aluout1E, result2W, result2M2, result2M, aluout2E,  
                                forward1_1D, src1_a1D);
    mux9 #(32) mux9_forward1_2D(Mrd2D, result1W, result1M2, result1M, aluout1E, result2W, result2M2, result2M, aluout2E,  
                                forward1_2D, src1_b1D);
    // Forward 2
    mux9 #(32) mux9_forward2_1D(Srd1D, result1W, result1M2, result1M, aluout1E, result2W, result2M2, result2M, aluout2E,  
                                forward2_1D, src2_a1D);
    mux9 #(32) mux9_forward2_2D(Srd2D, result1W, result1M2, result1M, aluout1E, result2W, result2M2, result2M, aluout2E,  
                                forward2_2D, src2_b1D);
    //choose immd1
    mux2 #(32) mux2_immd1(src1_b1D, immd1D ,dec_sign1D.is_imm,  src1_bD);
    mux2 #(32) mux2_immd2(src2_b1D, immd2D ,dec_sign2D.is_imm,  src2_bD);
    //choose jump
    mux2 #(32) mux2_jump1(src1_a1D, PcPlus8D, jump1D | branch1D, src1_aD);
    mux2 #(32) mux2_jump2(src2_a1D, PcPlus12D, jump2D | branch2D, src2_aD);
	// BranchPredict
    BranchPredict branch_predict(
        .clk(clk), .rst(rst),
        .flush_masterD(flush_masterD),.stall_masterD(stall_masterD), .flush_slaveD(flush_slaveD), .stall_slaveD(stall_slaveD),
        .instr1D(instr1D), .instr2D(instr2D), .PcF2(PcF2), .PcPlus4F2(PcPlus4F2), .pcE(pcE), .PcPlus4E(PcPlus4E),
        .branch1E(branch1E), .branch2E(branch2E),  .actual_take1E(actual_take1E), .actual_take2E(actual_take2E),

        .branch1D(branch1D), .branch2D(branch2D),
        .pred_take1D(pred_take1D) ,.pred_take2D(pred_take2D)
    );
    // jump, assign Logic
    jump_control jump_control(
        .instr1D(instr1D), .instr2D(instr2D),
        .PcPlus4D(PcPlus4D), .PcPlus8D(PcPlus8D),
        .src1_a1D(src1_a1D), .src2_a1D(src2_a1D),

        .jump1D(jump1D), .jump2D(jump2D),
        .pc_jump1D(pc_jump1D), .pc_jump2D(pc_jump2D) 
    );
	//----------------------------------Execute------------------------------------
    //-----------------------master---------------------------
    flopstrc #(32) flopPcE(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(PcD),.out(pcE));
    flopstrc #(32) flopInst1E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(instr1D),.out(instr1E));
    flopstrc #(32) flopSrc1a1E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(src1_a1D),.out(src1_a1E));
    flopstrc #(32) flopSrc1b1E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(src1_b1D),.out(src1_b1E));
    flopstrc #(32) flopSrc1aE(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(src1_aD),.out(src1_aE));
    flopstrc #(32) flopSrc1bE(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(src1_bD),.out(src1_bE));
    flopstrc #(32) flopPcplus8E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(PcPlus8D),.out(PcPlus8E));
    flopstrc #(32) flopPcbranch1E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(pc_branch1D),.out(pc_branch1E));
    flopstrc #(4) flopSign1E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),
        .in({branch1D,pred_take1D,delayslot_masterD, pc_errorD}),
        .out({branch1E,pred_take1E,delayslot_masterE, pc_errorE}));
    flopctrl flopctrl1E(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(dec_sign1D),.out(dec_sign1E));
    //-----------------------slave---------------------------
    flopstrc #(32) flopPc4E(.clk(clk),.rst(rst),.stall(stall_slaveE),.flush(flush_slaveE),.in(PcPlus4D),.out(PcPlus4E));
    flopstrc #(32) flopInst2E(.clk(clk),.rst(rst),.stall(stall_slaveE),.flush(flush_slaveE),.in(instr2D),.out(instr2E));
    flopstrc #(32) flopSrc2a1E(.clk(clk),.rst(rst),.stall(stall_slaveE),.flush(flush_slaveE),.in(src2_a1D),.out(src2_a1E));
    flopstrc #(32) flopSrc2b1E(.clk(clk),.rst(rst),.stall(stall_slaveE),.flush(flush_slaveE),.in(src2_b1D),.out(src2_b1E));
    flopstrc #(32) flopSrc2aE(.clk(clk),.rst(rst),.stall(stall_slaveE),.flush(flush_slaveE),.in(src2_aD),.out(src2_aE));
    flopstrc #(32) flopSrc2bE(.clk(clk),.rst(rst),.stall(stall_slaveE),.flush(flush_slaveE),.in(src2_bD),.out(src2_bE));
    flopstrc #(32) flopPcplus12E(.clk(clk),.rst(rst),.stall(stall_slaveE),.flush(flush_slaveE),.in(PcPlus12D),.out(PcPlus12E));
    flopstrc #(32) flopPcbranch2E(.clk(clk),.rst(rst),.stall(stall_slaveE),.flush(flush_slaveE),.in(pc_branch2D),.out(pc_branch2E));
    flopstrc #(3) flopSign2E(.clk(clk),.rst(rst),.stall(stall_slaveE),.flush(flush_slaveE),
        .in({branch2D, pred_take2D, delayslot_slaveD}),
        .out({branch2E, pred_take2E, delayslot_slaveE}));
    flopctrl flopctrl2E(.clk(clk),.rst(rst),.stall(stall_slaveE),.flush(flush_slaveE),.in(dec_sign2D),.out(dec_sign2E));
    //-----------------------ExFlop---------------------
	//ALU
    alu_top aluitem(
        //input
        .clk(clk),.rst(rst),.flush_slaveE(flush_slaveE),.flush_masterE(flush_masterE),
        .src1_aE(src1_aE), .src1_bE(src1_bE), .src2_aE(src2_aE), .src2_bE(src2_bE),
        .alucontrolE1(dec_sign1E.alucontrol), .alucontrolE2(dec_sign2E.alucontrol), 
        .fulsh_ex(fulsh_ex), .DivMulEn1(dec_sign1E.DivMulEn), .DivMulEn2(dec_sign2E.DivMulEn), 
        .instr1E(instr1E), .instr2E(instr2E),
        //output
        .alustallE(alu_stallE),.overflow1E(overflow1E), .overflow2E(overflow2E),
        .trap1E(trap1E), .trap2E(trap2E),
        .aluoutE1(aluout1E), .aluoutE2(aluout2E)
    );
    
	//在execute阶段得到真实branch跳转情况
    branch_check branch_check1(
        .branch_judge_controlE(dec_sign1E.branch_judge_control),
        .rs_valueE(src1_a1E),
        .rt_valueE(src1_b1E),
        .actual_takeE(actual_take1E)
    );
    branch_check branch_check2(
        .branch_judge_controlE(dec_sign2E.branch_judge_control),
        .rs_valueE(src2_a1E),
        .rt_valueE(src2_b1E),
        .actual_takeE(actual_take2E)
    );
    //分支预测结果
    
    assign pred_failedE = (pred_take1E ^ actual_take1E) | (pred_take2E ^ actual_take2E);
    assign pred_failed_masterE = pred_take1E ^ actual_take1E;
    assign pred_failed_slaveE = pred_take2E ^ actual_take2E;
	//-------------------------------------Memory----------------------------------------
    //-----------------------master---------------------------
	flopstrc #(32) flopPcM(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(pcE),.out(pcM));
	flopstrc #(32) flopAlu1M(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(aluout1E),.out(aluout1M));
	flopstrc #(32) flopRtvalue1M(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(src1_b1E),.out(src1_b1M));
	flopstrc #(32) flopInstr1M(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(instr1E),.out(instr1M));
    flopstrc #(4) flopSign1M(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),
        .in({delayslot_masterE, overflow1E, trap1E, pc_errorE}),
        .out({delayslot_masterM, overflow1M, trap1M, pc_errorM}));
    flopctrl flopctrl1M(.clk(clk),.rst(rst),.stall(stall_masterE),.flush(flush_masterE),.in(dec_sign1D),.out(dec_sign1E));
    //-----------------------slave---------------------------
	flopstrc #(32) flopPcPlus4M(.clk(clk),.rst(rst),.stall(stall_masterM),.flush(flush_masterM),.in(PcPlus4E),.out(PcPlus4M));
	flopstrc #(32) flopAlu2M(.clk(clk),.rst(rst),.stall(stall_slaveM),.flush(flush_slaveM),.in(aluout2E),.out(aluout2M));
	flopstrc #(32) flopRtvalue2M(.clk(clk),.rst(rst),.stall(stall_slaveM),.flush(flush_slaveM),.in(src2_b1E),.out(src2_b1M));
	flopstrc #(32) flopInstr2M(.clk(clk),.rst(rst),.stall(stall_slaveM),.flush(flush_slaveM),.in(instr2E),.out(instr2M));
    flopstrc #(3) flopSign2M(.clk(clk),.rst(rst),.stall(stall_slaveM),.flush(flush_slaveM),
        .in({delayslot_slaveE, overflow2E, trap2E}),
        .out({delayslot_slaveM, overflow2M, trap2M}));
    flopctrl flopctrl2M(.clk(clk),.rst(rst),.stall(stall_slaveM),.flush(flush_slaveM),.in(dec_sign2D),.out(dec_sign2E));
    //----------------------MemoryFlop------------------------
    wire [31:0] data_srcM;
    assign mem_enM = (dec_sign1M.mem_read | dec_sign2M.mem_read | dec_sign1M.mem_write | dec_sign2M.mem_write) & ~fulsh_ex; //意外刷新时需要
    wire mem_sel = dec_sign1M.mem_read | dec_sign1M.mem_write;
    // Assign Logical
    wire Blank_SL = (virtual_data_addrM2[31:2] == virtual_data_addrW[31:2]) & (virtual_data_addrM2[31:29] != 3'b101) 
            & (dec_sign1M2.mem_read | dec_sign2M2.mem_read) &  (dec_sign1W.mem_write | dec_sign2W.mem_write);
    mem_control mem_control(
        .instr1M(instr1M), .instr1M2(instr1M2), .address1M(aluout1M), .address1M2(aluout1M2),
        .instr2M(instr2M), .instr2M2(instr2M2), .address2M(aluout2M), .address2M2(aluout2M2),
        .mem_sel(mem_sel), .Blank_SL(Blank_SL),
        
        .data_wdata1M(src1_b1M),.data_wdata2M(src2_b1M),    //原始的wdata
        .rt_valueM2(data_srcM2),
        .writedataM(writedataM), .writedataW(writedataW),   //新的wdata
        .mem_write_selectM(mem_write_selectM), .mem_write_selectW(mem_write_selectW),
        .data_addrM(virtual_data_addrM), .data_srcM(data_srcM),
        .mem_rdataM2(mem_rdataM2), .data_rdataM2(result_rdataM2),

        .addr_error_sw1(addrErrorSw1M), .addr_error_lw1(addrErrorLw1M),
        .addr_error_sw2(addrErrorSw2M), .addr_error_lw2(addrErrorLw2M)
    );

    //在aluout1M2, cp0_outM2 中选择写入寄存器的数据 Todo
    mux2 #(32) mux2_memtoreg1M(aluout1M, cp0_out1M2, dec_sign1M.is_mfc, result1M);
    mux2 #(32) mux2_memtoreg2M(aluout2M, cp0_out2M2, dec_sign2M.is_mfc, result2M);
     //异常处理
    exception exception1(
        .rst(rst),.ext_int(ext_int),
        //异常信号
        .ri(dec_sign1M.ri), .break_exception(dec_sign1M.breaks), .syscall(dec_sign1M.syscall), 
        .overflow(overflow1M), .addrErrorSw(addrErrorSw1M), .addrErrorLw(addrErrorLw1M), 
        .pcError(pcErrorM), .eretM(dec_sign1M.eret), .trap(trap1M),
        //异常寄存器
        .cp0_status(cp0_statusM2), .cp0_cause(cp0_causeM2), .cp0_epc(cp0_epcM2),
        //记录出错地址
        .pcM(pcM),.aluoutM(aluout1M),
        //输出异常处理信号
        .except_type(except_type1M),.flush_exception(flush_exception_masterM),
        .pc_exception(pc_exception1M),
        .pc_trap(pc_trap1M),.badvaddrM(badvaddr1M)
    );
    exception exception2(
        .rst(rst),.ext_int(ext_int),
        //异常信号
        .ri(dec_sign2M.ri), .break_exception(dec_sign2M.breaks), .syscall(dec_sign2M.syscall), 
        .overflow(overflow2M), .addrErrorSw(addrErrorSw2M), .addrErrorLw(addrErrorLw2M), 
        .pcError(pcErrorM), .eretM(dec_sign2M.eret), .trap(trap2M),
        //异常寄存器
        .cp0_status(cp0_statusM2), .cp0_cause(cp0_causeM2), .cp0_epc(cp0_epcM2),
        //记录出错地址
        .pcM(PcPlus4M),.aluoutM(aluout2M),
        //输出异常处理信号
        .except_type(except_type2M),.flush_exception(flush_exception_slaveM),
        .pc_exception(pc_exception2M),
        .pc_trap(pc_trap2M),.badvaddrM(badvaddr2M)
    );
     // cp0 todo 
    cp0_reg cp0(
        .clk(clk) , .rst(rst),
        .stall_masterM(stall_masterM), .we1_i(dec_sign1M.cp0_write) , .we2_i(dec_sign2M.cp0_write) ,
        .waddr1_i(instr1M[15:11]) , .raddr1_i(instr1M[15:11]), .waddr2_i(instr2M[15:11]) , .raddr2_i(instr2M[15:11]),
        .data1_i(src1_b1M), .data2_i(src2_b1M), .int_i(ext_int),
        .excepttype1_i(except_type1M) , .excepttype2_i(except_type2M), 
        .current_inst_addr1_i(pcM), .current_inst_addr2_i(PcPlus4M),
        .is_in_delayslot1_i(delayslot_masterM) , .is_in_delayslot2_i(delayslot_slaveM), 
        .bad_addr1_i(badvaddr1M), .bad_addr2_i(badvaddr2M),
        .status_o(cp0_statusM2) , .cause_o(cp0_causeM2) ,
        .epc_o(cp0_epcM2), .data1_o(cp0_out1M2), .data2_o(cp0_out2M2)
    );
	//-------------------------------------Memory2-------------------------------------------------
    wire is_mfcM2, mem_writeM2; // for debug
    wire [3:0] mem_write_selectM2;
    wire [31:0] virtual_data_addrM2, writedataM2, data_srcM2;
    // todo M2 flop
    //-----------------------master---------------------------
	flopstrc #(4) flopMemSelM2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in({mem_write_selectM}),.out({mem_write_selectM2}));
	flopstrc #(32) flopAddrM2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in(virtual_data_addrM),.out(virtual_data_addrM2));
	flopstrc #(32) flopPc1M2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in(pcM),.out(pcM2));
    flopstrc #(32) flopRtvalueM2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in(data_srcM),.out(data_srcM2));
    flopstrc #(32) flopWdataM2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in(writedataM),.out(writedataM2));
	flopstrc #(32) flopInstr1M2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in(instr1M),.out(instr1M2));
	flopstrc #(32) flopRes1M2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in(result1M),.out(result1_cdataM2));
    flopctrl flopctrl1M2(.clk(clk),.rst(rst),.stall(stall_masterM2),.flush(flush_masterM2),.in(dec_sign1E),.out(dec_sign1M));
    //-----------------------slave---------------------------
	flopstrc #(32) flopPc2M2(.clk(clk),.rst(rst),.stall(stall_slaveM2),.flush(flush_slaveM2),.in(PcPlus4M),.out(PcPlus4M2));
	flopstrc #(32) flopInstr2M2(.clk(clk),.rst(rst),.stall(stall_slaveM2),.flush(flush_slaveM2),.in(instr2M),.out(instr2M2));
	flopstrc #(32) flopRes2M2(.clk(clk),.rst(rst),.stall(stall_slaveM2),.flush(flush_slaveM2),.in(result2M),.out(result2_cdataM2));
    flopctrl flopctrl2M2(.clk(clk),.rst(rst),.stall(stall_slaveM2),.flush(flush_slaveM2),.in(dec_sign2E),.out(dec_sign2M));
	//------------------Memory2_Flop--------------------------
    mux2 #(32) mux2_memtoreg1(result1_cdataM2,result_rdataM2, dec_sign1M2.mem_read,result1M2);
    mux2 #(32) mux2_memtoreg2(result2_cdataM2,result_rdataM2, dec_sign2M2.mem_read,result2M2);
	//-------------------------------------Write_Back-------------------------------------------------
    wire [3:0] mem_write_selectW;
    wire [31:0] instr1W, instr2W; // for debug
    wire [31:0] virtual_data_addrW, writedataW;
    //-----------------------master---------------------------
	flopstrc #(4) flopWriregW(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),.in(mem_write_selectM2),.out(mem_write_selectM2));
	flopstrc #(32) flopInstr1W(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),.in(instr1M2),.out(instr1W));
	flopstrc #(32) flopPcW(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),.in(pcM2),.out(pcW));
	flopstrc #(32) flopvaddr1W(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),.in(virtual_data_addrM2),.out(virtual_data_addrW));
	flopstrc #(32) flopRes1W(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),.in(result1M2),.out(result1W));
    flopstrc #(32) flopWdataW(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),.in(writedataM2),.out(writedataW));
    flopctrl flopctrl1W(.clk(clk),.rst(rst),.stall(stall_masterW),.flush(flushW),.in(dec_sign1M2),.out(dec_sign1W));
    //-----------------------slave---------------------------
	flopstrc #(32) flopPc2W(.clk(clk),.rst(rst),.stall(stall_slaveW),.flush(flushW),.in(PcPlus4M2),.out(PcPlus4W));
	flopstrc #(32) flopInstr2W(.clk(clk),.rst(rst),.stall(stall_slaveW),.flush(flushW),.in(instr2M2),.out(instr2W));
	flopstrc #(32) flopRes2W(.clk(clk),.rst(rst),.stall(stall_slaveW),.flush(flushW),.in(result2M2),.out(result2W));
    flopctrl flopctrl2W(.clk(clk),.rst(rst),.stall(stall_slaveW),.flush(flushW),.in(dec_sign2M2),.out(dec_sign2W));
	//------------------Write_Back_Flop--------------------------
	
endmodule
