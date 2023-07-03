`timescale 1ns / 1ps



module datapath(

	input wire clk,rst,
	
	input wire  [5 :0] ext_int, //异常处理
    
    //inst
    output wire [31:0] inst_addrF,  //指令地址
    output wire        inst_enF,  //使能
    input wire  [31:0] instrF,  //注：instr ram时钟取反
    input wire         i_cache_stall,

    //data
    output wire mem_enM,                    
    output wire [31:0] mem_addrM,     //写地址
    input  wire [31:0] mem_rdataM,    //读数据
    output wire [3 :0] mem_write_selectM,      //写使能
    output wire [31:0] writedataM,    //写数据
    input wire         d_cache_stall,

    output wire        longest_stall,
	//debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
    );
	
	//--------fetch stage----------
	wire [31:0] pcplus4F;    //pc
    wire [31:0] instrF_4;                   //instrF末尾为2'b00
    
    wire pc_errorF;  // pc错误

    wire is_in_delayslot_iF; // 此时的D阶段（即上一条指令）是否为跳转指令
    // wire pcerrorD, pcerrorE, pcerrorM; 
	//----------decode stage---------
	wire[3:0] aluopD;
	wire[4:0] alucontrolD;
	 wire [31:0] instrD;  //指令
    wire [31:0] pcD, pcplus4D;  //pc
    wire [31:0] src_a1D, src_b1D; //alu输入（操作数
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
    wire [1:0]  forward_1D;
    wire [1:0]  forward_2D;
    wire        stallDblank;
	//-------execute stage----------
	wire [31:0] pcE, pcplus4E , mem_wdataE, immE; //pc pc+4 寄存器号 写内存 立即数
    wire        pred_takeE;  //分支预测
    wire [1 :0] regdstE;  //写回选择信号, 00-> rd, 01-> rt, 10-> $ra
    wire [4 :0] alucontrolE;  //alu控制信号

    wire [31:0] src_a1E, src_b1E; //alu输入（操作数
    wire [31:0] src_aE, src_bE; //alu输入（操作数
    wire [63:0] aluoutE; //alu输出
    wire        is_immE;  //alu srcb选择 0->rd2E, 1->immE
    wire [4 :0] writeregE; //写寄存器号
    wire        branchE; //分支信号
    wire [31:0] pc_branchE;  //分支跳转pc

    wire [31:0] instrE;
    wire [31:0] pc_jumpE;  //jump pc
    wire        jump_conflictE; //jump冲突
    wire        regwriteE;	//寄存器写
    wire        alu_stallE;  //alu暂停
    wire        flush_jump_conflictE;  //jump冲突
    wire        jumpE; //jump信号
    wire        actual_takeE;  //分支预测 实际结果
    wire [2 :0] branch_judge_controlE; //分支判断控制
	wire        memtoregE, mem_readE, mem_writeE;
    wire [1:0]  hilo_selectE;  //高位1表示是mhl指令，0表示是乘除法
                              //低位1表示是用hi，0表示用lo
	wire        hilotoregE;//hilo到寄存器
    wire        hilo_writeE;  //hilo写使
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

    wire [31:0] result_rdataM;
    wire [31:0] hilo_outM;  //hilo输出
    wire        hilotoregM; 
	wire		is_mfcM;
	wire        mfhiM;
	wire        mfloM;

    wire [31:0] rt_valueM;
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
    wire [31:0] cp0_statusM;  //status输出
    wire [31:0] cp0_causeM;  //cause输出
    wire [31:0] cp0_epcM;  //epc输出
    wire        flush_exceptionM;  // 发生异常时需要刷新流水线
    wire [31:0] pc_exceptionM; //异常处理的地址0xbfc0_0380，若为eret指令 则为返回地址
    wire        pc_trapM; // 发生异常时pc特殊处理
    wire [31:0] badvaddrM;
    wire        is_in_delayslot_iM;
    wire        cp0_to_regM;
    wire        cp0_writeM;
    
	//------writeback stage----------
	wire [4:0] writeregW;//写寄存器号
	wire regwriteW;
	wire [31:0] resultW;
    wire [31:0] cp0_statusW, cp0_causeW, cp0_epcW, cp0_outW;
    //------stall sign---------------
    wire stallF,stallD,stallE,stallM,stallW;
    wire flushF,flushD,flushE,flushM,flushW;
//------------------------------------------Data------------------------------------------
	//--------------------debug---------------------
    assign debug_wb_pc          = pcM;
    assign debug_wb_rf_wen      = {4{regwriteM & ~stallW & ~flush_exceptionM }};
    assign debug_wb_rf_wnum     = writeregM;
    assign debug_wb_rf_wdata    = resultM;

    //--------------------------------------Fetch------------------------------------------------
    assign pc_errorF = (~|(inst_addrF[1:0] ^ 2'b0)) ? 1'b0 : 1'b1; 
    
    assign inst_enF = ~flush_exceptionM & ~pc_errorF & ~flush_pred_failedM & ~flush_jump_conflictE & ~stallDblank;
    wire [31:0] instrF_valid;
    assign instrF_valid = {32{inst_enF}}&instrF;  //丢掉无效指令
    // pc+4
    assign pcplus4F = inst_addrF + 4;
    assign is_in_delayslot_iF = branchD | jumpD; //通过前一条指令，判断是否是延迟槽
    // pc reg
    pc_reg pc(
        .clk(clk),
        .rst(rst),
        .stallF(stallF),
        .branchD(branchD),
        .branchM(branchM),
        .pre_right(pre_right),
        .actual_takeM(actual_takeM),
        .pred_takeD(pred_takeD),
        .pc_trapM(pc_trapM),
        .jumpD(jumpD),
        .jump_conflictD(jump_conflictD),
        .jump_conflictE(jump_conflictE),

        .pc_exceptionM(pc_exceptionM),
        .pcplus4E(pcplus4E),
        .pc_branchM(pc_branchM),
        .pc_jumpE(pc_jumpE),
        .pc_jumpD(pc_jumpD),
        .pc_branchD(pc_branchD),
        .pcplus4F(pcplus4F),

        .pc(inst_addrF)
    );

	//----------------------------------------Decode------------------------------------------------
    flopstrc #(32) flopPcplusF(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),.in(pcplus4F),.out(pcplus4D));
    flopstrc #(32) flopPcF(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),.in(inst_addrF),.out(pcD));
    flopstrc #(32) flopInstF(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),.in(instrF_valid),.out(instrD));
    flopstrc #(1) flopIsdelayF(.clk(clk),.rst(rst),.stall(stallD),.flush(flushD),
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
    assign pc_branchD = {immD[29:0], 2'b00} + pcplus4D;
    //选择writeback寄存器     rd             rt
    mux3 #(5) mux3_regdst(instrD[15:11],instrD[20:16],5'd31,regdstD,  writeregD);
    //前推至ID阶段
    mux4 #(32) mux4_forward_1E(rd1D,resultM,resultW,aluoutE[31:0],forward_1D,  src_a1D);
    mux4 #(32) mux4_forward_2E(rd2D,resultM,resultW,aluoutE[31:0],forward_2D, src_b1D);
	// BranchPredict
    BranchPredict branch_predict(
        .clk(clk), .rst(rst),
        .flushD(flushD),.stallD(stallD),.instrD(instrD),
        
        .immD(immD),
        .pcF(inst_addrF),
        .pcM(pcM),
        .branchM(branchM),
        .actual_takeM(actual_takeM),

        .branchD(branchD),
        .pred_takeD(pred_takeD)
    );
    // jump, assign Logic
    jump_control jump_control(
        .instrD(instrD),
        .pcplus4D(pcplus4D),
        .rd1D(rd1D),
        .regwriteE(regwriteE), .writeregE(writeregE), 
        .regwriteM(regwriteM), .writeregM(writeregM),
        .regwriteW(regwriteW), .writeregW(writeregW),

        .jumpD(jumpD),                      //是jump类指令(j, jr)
        .jump_conflictD(jump_conflictD),    //jr rs寄存器发生冲突
        .pc_jumpD(pc_jumpD)                 //D阶段最终跳转地址
    );
	//----------------------------------Execute------------------------------------
    flopstrc #(32) flopPcD(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(pcD),.out(pcE));
    flopstrc #(32) flopInstD(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(instrD),.out(instrE));
    flopstrc #(32) flopSrcbD(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(src_a1D),.out(src_a1E));
    flopstrc #(32) flopSrcaD(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(src_b1D),.out(src_b1E));
    flopstrc #(32) flopImmD(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(immD),.out(immE));
    flopstrc #(32) flopPcplus4D(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(pcplus4D),.out(pcplus4E));
    flopstrc #(32) flopPcbranchD(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),.in(pc_branchD),.out(pc_branchE));
    flopstrc #(10) flopSign1D(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),
        .in({branchD,pred_takeD,jumpD,is_in_delayslot_iD,jump_conflictD,is_immD,regwriteD,riD,breakD,hilotoregD}),
        .out({branchE,pred_takeE,jumpE,is_in_delayslot_iE,jump_conflictE,is_immE,regwriteE,riE,breakE,hilotoregE}));
    flopstrc #(10) flopSign2D(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),
        .in({memtoregD,mem_writeD,mem_readD,syscallD,eretD,cp0_to_regD,is_mfcD,mfloD,mfhiD,cp0_writeD}),
        .out({memtoregE,mem_writeE,mem_readE,syscallE,eretE,cp0_to_regE,is_mfcE,mfloE,mfhiE,cp0_writeE}));
    flopstrc #(15) flopSign3D(.clk(clk),.rst(rst),.stall(stallE),.flush(flushE),
        .in({alucontrolD,branch_judge_controlD,writeregD,regdstD}),
        .out({alucontrolE,branch_judge_controlE,writeregE,regdstE}));
    //-----------------------ExFlop---------------------
	//ALU
    alu alu(
        .clk(clk),.rst(rst),.stallE(stallE),.flushE(flushE),
        .src_aE(src_aE), .src_bE(src_bE),
        .alucontrolE(alucontrolE),.sa(instrE[10:6]),

        .hilo_writeE(hilo_writeE) , .hilo_selectE(hilo_selectE),.div_stallE(alu_stallE),
        .aluoutE(aluoutE) , .overflowE(overflowE)
    );
    //choose jump
    mux2 #(32) mux2_jump(src_a1E,pcplus4D,jumpE | branchE,src_aE);
    //choose imm
    mux2 #(32) mux2_imm(src_b1E,immE,is_immE,  src_bE);

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
	flopstrc #(32) flopPcE(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(pcE),.out(pcM));
	flopstrc #(64) flopAluE(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(aluoutE),.out(aluoutM));
	flopstrc #(32) flopRtvalueE(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(src_b1E),.out(rt_valueM));
	flopstrc #(32) flopInstrE(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(instrE),.out(instrM));
	flopstrc #(32) flopPcbE(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(pc_branchE),.out(pc_branchM));
    flopstrc #(10) flopSign1E(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),
        .in({regwriteE,pred_takeE,branchE,is_in_delayslot_iE,actual_takeE,mem_readE,mem_writeE,memtoregE,breakE,hilotoregE}),
        .out({regwriteM,pred_takeM,branchM,is_in_delayslot_iM,actual_takeM,mem_readM,mem_writeM,memtoregM,breakM,hilotoregM}));
    flopstrc #(10) flopSign2E(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),
        .in({riE,syscallE,eretE,cp0_writeE,cp0_to_regE,is_mfcE,mfhiE,mfloE,breakE,hilotoregE}),
        .out({riM,syscallM,eretM,cp0_writeM,cp0_to_regM,is_mfcM,mfhiM,mfloM,breakM,hilotoregM}));
    flopstrc #(6) flopWriteregE(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),
        .in({writeregE,overflowE}),.out({writeregM,overflowM}));
    //----------------------MemoryFlop------------------------
    assign mem_enM = (mem_readM  |  mem_writeM) & ~flush_exceptionM;; //意外刷新时需要
    // Assign Logical
    mem_control mem_control(
        .instrM(instrM), .addr(aluoutM),
    
        .data_wdataM(rt_valueM),    //原始的wdata
        .writedataM(writedataM),    //新的wdata
        .mem_write_selectM(mem_write_selectM),
        .data_addrM(mem_addrM),
        .mem_rdataM(mem_rdataM), .data_rdataM(result_rdataM),

        .addr_error_sw(addrErrorSwM), .addr_error_lw(addrErrorLwM)  
    );
    wire hilo_write_re;
    assign hilo_write_re=hilo_writeE&~flush_exceptionM;//防止异常刷新时的错误写入

    // hilo
    hilo hilo(clk,rst,hilo_selectE,hilo_write_re,mfhiM,mfloM,aluoutE,hilo_outM);
    //后两位不为0
    assign pcErrorM = |(pcM[1:0] ^ 2'b00);  
    //在aluoutM, result_rdataM, hilo_outM, cp0_outW 中选择写入寄存器的数据
    mux4 #(32) mux4_memtoreg(aluoutM, result_rdataM, hilo_outM, cp0_outW, 
                            {hilotoregM, memtoregM} | {2{is_mfcM}},
                            resultM);
     //异常处理
    exception exception(
        .rst(rst),.ext_int(ext_int),
        //异常信号
        .ri(riM), .break_exception(breakM), .syscall(syscallM), .overflow(overflowM), 
        .addrErrorSw(addrErrorSwM), .addrErrorLw(addrErrorLwM), .pcError(pcErrorM), .eretM(eretM),
        //异常寄存器
        .cp0_status(cp0_statusW), .cp0_cause(cp0_causeW), .cp0_epc(cp0_epcW),
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
        .data_i(rt_valueM) , .int_i(ext_int),
        
        .data_o(cp0_outW),

        .excepttype_i(except_typeM) , .current_inst_addr_i(pcM),
        .is_in_delayslot_i(is_in_delayslot_iM) , .bad_addr_i(badvaddrM),

        .status_o(cp0_statusW) , .cause_o(cp0_causeW) , .epc_o(cp0_epcW)
    );
    //分支预测结果
    assign pre_right = ~(pred_takeM ^ actual_takeM); 
    assign flush_pred_failedM = ~pre_right;
	//-------------------------------------Write_Back-------------------------------------------------
	flopstrc #(6) flopWriregM(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),
            .in({writeregM,regwriteM}),
            .out({writeregW,regwriteW}));
	flopstrc #(32) flopResM(.clk(clk),.rst(rst),.stall(stallW),.flush(flushW),.in(resultM),.out(resultW));
	//------------------Write_Back_Flop--------------------------

	//hazard detection
	hazard hazard0(
        .i_cache_stall(i_cache_stall),
        .d_cache_stall(d_cache_stall),
        .alu_stallE(alu_stallE),

        .flush_jump_conflictE   (flush_jump_conflictE),
        .flush_pred_failedM     (flush_pred_failedM),
        .flush_exceptionM       (flush_exceptionM),

        .rsD(instrD[25:21]),
        .rtD(instrD[20:16]),
        .is_mfcE(is_mfcE),
        .hilotoregE(hilotoregE),
        .regwriteE(regwriteE),
        .regwriteM(regwriteM),
        .regwriteW(regwriteW),
        .writeregE(writeregE),
        .writeregM(writeregM),
        .writeregW(writeregW),
        .mem_readE(mem_readE),
        .mem_readM(mem_readM),

        .stallF(stallF), .stallD(stallD), .stallE(stallE), .stallM(stallM), .stallW(stallW),
        .flushF(flushF), .flushD(flushD), .flushE(flushE), .flushM(flushM), .flushW(flushW),
        .longest_stall(longest_stall), .stallDblank(stallDblank),
        .forward_1D(forward_1D), .forward_2D(forward_2D)
    );
	
endmodule
