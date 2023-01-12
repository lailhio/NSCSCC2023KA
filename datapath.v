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
	wire [31:0] pcF, pcplus4F;    //pc
    wire [31:0] instrF_4;                   //instrF末尾为2'b00
    
    wire pc_errorF;  // pc错误

    wire is_in_delayslot_iF; // 此时的D阶段（即上一条指令）是否为跳转指令
    // wire pcerrorD, pcerrorE, pcerrorM; 
	//----------decode stage---------
	wire[3:0] aluopD;
	wire[4:0] alucontrolD;
	 wire [31:0] instrD;  //指令
    wire [4 :0] rsD, rtD, rdD, saD;  //rs rt rd 寄存器号
    wire [31:0] pcD, pcplus4D;  //pc

    wire [31:0] rd1D, rd2D, immD, pc_branchD, pc_jumpD;  //寄存器读出数据 立即数 pc分支 跳转
    wire        pred_takeD, branchD, jumpD;  //立即数扩展 分支预测 branch jump信号
    wire        flush_pred_failedM;  //分支预测失败

    wire        jump_conflictD;  //jump冲突
    wire [2 :0] branch_judge_controlD; //分支判断控制
	wire 		sign_exD;          //立即数是否为符号扩展
	wire [1:0] 	regdstD;    	//写寄存器选择  00-> rd, 01-> rt, 10-> $ra
	wire 		is_immD;       //alu srcb选择 0->rd2E, 1->immE
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
	//-------execute stage----------
	wire [31:0] pcE, pcplus4E ,rd1E, rd2E, mem_wdataE, immE; //pc pc+4 寄存器号 写内存 立即数
    wire [4 :0] rsE, rtE, rdE, saE;  //寄存器号
    wire        pred_takeE;  //分支预测
    wire [1 :0] regdstE;  //写回选择信号, 00-> rd, 01-> rt, 10-> $ra
    wire [4 :0] alucontrolE;  //alu控制信号

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
    wire [31:0] rs_valueE, rt_valueE;  //rs rt寄存器的
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
    wire [1:0]  forward_1E;
    wire [1:0]  forward_2E;
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
    wire [31:0] writedataM_temp;
    wire [31:0] hilo_outM;  //hilo输出
    wire        hilotoregM; 
	wire		is_mfcM;
	wire        mfhiM;
	wire        mfloM;


    wire [4:0] 	rdM;
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
    wire        flush_exceptionW;  // 发生异常时需要刷新流水线
    wire [31:0] pc_exceptionM; //异常处理的地址0xbfc0_0380，若为eret指令 则为返回地址
    wire        pc_trapM; // 发生异常时pc特殊处理
    wire [31:0] badvaddrM;
    wire        is_in_delayslot_iM;
    wire        cp0_to_regM;
    wire        cp0_writeM;
    
	//------writeback stage----------
	wire [4:0] writeregW;//写寄存器号
	wire regwriteW;
	wire [31:0] aluoutW,resultW;
	wire [31:0] pcW;
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
    assign inst_addrF = pcF; //F阶段地址
    assign pc_errorF = (~|(pcF[1:0] ^ 2'b0)) ? 1'b0 : 1'b1; 
    
    assign inst_enF = ~flush_exceptionM & ~pc_errorF & ~flush_pred_failedM & ~flush_jump_conflictE;
    wire [31:0] instrF_valid;
    assign instrF_valid = {32{inst_enF}}&instrF;  //丢掉无效指令
    // pc+4
    assign pcplus4F = pcF + 4;
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

        .pc(pcF)
    );

	//----------------------------------------Decode------------------------------------------------

    Fetch_Decode Fe_De(
        .clk(clk), .rst(rst),
        .stallD(stallD),
        .flushD(flushD),

        .pcF(pcF),
        .pcplus4F(pcplus4F),
        .instrF(instrF_valid),
        .is_in_delayslot_iF(is_in_delayslot_iF), //上一条指令是跳转
        
        .pcD(pcD),
        .pcplus4D(pcplus4D),
        .instrD(instrD),
        .is_in_delayslot_iD(is_in_delayslot_iD)  //处于延迟
    );
    wire[5:0] functD;
	assign opD = instrD[31:26];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];
	aludec ad(functD,aluopD,alucontrolD);
	maindec md(
		instrD,
		//output
		sign_exD,
		regdstD,is_immD,regwriteD,
		mem_readD, mem_writeD,
		memtoregD,
		hilotoregD,riD,
		breakD, syscallD, eretD, 
		cp0_writeD,
		cp0_to_regD,
        mfhiD,mfloD,
		is_mfcD,  
		aluopD,
        functD,
		branch_judge_controlD
		);
    //扩展立即数
    signext signex(sign_exD,instrD[15:0],immD);
	//regfile，decode阶段读出，writeback阶段写入
	regfile rf(clk,rst,stallW,regwriteW,rsD,rtD,writeregW,resultW,rd1D,rd2D);
    // 立即数左移2 + pc+4得到分支跳转地址   
    assign pc_branchD = {immD[29:0], 2'b00} + pcplus4D;

	//分支预测
    BranchPredict branch_predict(
        .clk(clk), .rst(rst),

        .flushD(flushD),
        .stallD(stallD),

        .instrD(instrD),
        .immD(immD),
        .pcF(pcF),
        .pcM(pcM),
        .branchM(branchM),
        .actual_takeM(actual_takeM),

        .branchD(branchD),
        .pred_takeD(pred_takeD)
    );
    // jump指令控制
    jump_control jump_control(
        .instrD(instrD),
        .pcplus4D(pcplus4D),
        .rd1D(rd1D),
        .regwriteE(regwriteE), .regwriteM(regwriteM),
        .writeregE(writeregE), .writeregM(writeregM),

        .jumpD(jumpD),                      //是jump类指令(j, jr)
        .jump_conflictD(jump_conflictD),    //jr rs寄存器发生冲突
        .pc_jumpD(pc_jumpD)                 //D阶段最终跳转地址
    );
	//----------------------------------Execute------------------------------------
	Decode_Execute De_Ex(
        .clk(clk),
        .rst(rst),
        .stallE(stallE),
        .flushE(flushE),
	//Decode stage
        .pcD(pcD),
        .rsD(rsD), .rd1D(rd1D), .rd2D(rd2D),
        .rtD(rtD), .rdD(rdD),
        .immD(immD),
        .pcplus4D(pcplus4D),
        .instrD(instrD),
        .branchD(branchD),.pred_takeD(pred_takeD),
        .pc_branchD(pc_branchD),.jump_conflictD(jump_conflictD),
        .is_in_delayslot_iD(is_in_delayslot_iD),
        .saD(saD),
        .alucontrolD(alucontrolD),
        .jumpD(jumpD),
        .branch_judge_controlD(branch_judge_controlD),
		.regdstD(regdstD),
		.is_immD(is_immD),.regwriteD(regwriteD),
		.mem_readD(mem_readD),.mem_writeD(mem_writeD),.memtoregD(memtoregD),
		.hilotoregD(hilotoregD),.riD(riD),.breakD(breakD),
		.syscallD(syscallD),.eretD(eretD),.cp0_writeD(cp0_writeD),
		.cp0_to_regD(cp0_to_regD),.is_mfcD(is_mfcD),
        .mfhiD(mfhiD),.mfloD(mfloD),
	//Execute stage
        .pcE(pcE),
        .rsE(rsE), .rd1E(rd1E), .rd2E(rd2E),
        .rtE(rtE), .rdE(rdE),
        .immE(immE),
        .pcplus4E(pcplus4E),
        .instrE(instrE),
        .branchE(branchE),.pred_takeE(pred_takeE),
        .pc_branchE(pc_branchE),.jump_conflictE(jump_conflictE),
        .is_in_delayslot_iE(is_in_delayslot_iE),
        .saE(saE),
        .alucontrolE(alucontrolE),
        .jumpE(jumpE),
        .branch_judge_controlE(branch_judge_controlE),
		.regdstE(regdstE),
		.is_immE(is_immE),.regwriteE(regwriteE),
		.mem_readE(mem_readE),.mem_writeE(mem_writeE),.memtoregE(memtoregE),
		.hilotoregE(hilotoregE),.riE(riE),.breakE(breakE),
		.syscallE(syscallE),.eretE(eretE),.cp0_writeE(cp0_writeE),
		.cp0_to_regE(cp0_to_regE),.is_mfcE(is_mfcE),
        .mfhiE(mfhiE),.mfloE(mfloE)
    );
	//ALU
    alu alu(
        .clk(clk),
        .rst(rst),.stallE(stallE),
        .flushE(flushE),
        .src_aE(src_aE), .src_bE(src_bE),
        .alucontrolE(alucontrolE),
        .sa(saE),

        .hilo_writeE(hilo_writeE),
        .hilo_selectE(hilo_selectE),
        .div_stallE(alu_stallE),
        .aluoutE(aluoutE),
        .overflowE(overflowE)
    );

    mux4 #(5) mux4_regdst(
        rdE,rtE,5'd31,5'b0,
        regdstE, 
        writeregE //选择writeback寄存器
    );

    mux4 #(32) mux4_forward_1E(
        rd1E,resultM,resultW,pcplus4D,  
                                             
        {2{jumpE | branchE}} |forward_1E,  
        src_aE
    );
    mux4 #(32) mux4_forward_2E(
        rd2E,resultM,resultW,immE, 
        {2{is_immE}} | forward_2E,  
        src_bE
    );
    mux4 #(32) mux4_rs_valueE(rd1E, resultM, resultW, 32'b0, forward_1E, rs_valueE); //数据前推后的rs寄存器
    mux4 #(32) mux4_rt_valueE(rd2E, resultM, resultW, 32'b0, forward_2E, rt_valueE); //数据前推后的rt寄存器

	//在execute阶段得到真实branch跳转情况
    branch_check branch_check(
        .branch_judge_controlE(branch_judge_controlE),
        .rs_valueE(rs_valueE),
        .rt_valueE(rt_valueE),
        .actual_takeE(actual_takeE)
    );
    
    assign pc_jumpE = rs_valueE; //jr指令 跳转到rs
    assign flush_jump_conflictE = jump_conflictE;
	//-------------------------------------Mem----------------------------------------
	
	Execute_Mem Ex_Me(
        .clk(clk),.rst(rst),.stallM(stallM),.flushM(flushM),

        .pcE(pcE),
        .aluoutE(aluoutE),
        .rt_valueE(rt_valueE),
        .writeregE(writeregE),.regwriteE(regwriteE),
        .instrE(instrE),
        .branchE(branchE),.pred_takeE(pred_takeE),.pc_branchE(pc_branchE),
        .overflowE(overflowE),
        .is_in_delayslot_iE(is_in_delayslot_iE),
        .rdE(rdE),
        .actual_takeE(actual_takeE),
		.mem_readE(mem_readE),.mem_writeE(mem_writeE),.memtoregE(memtoregE),
		.hilotoregE(hilotoregE),.riE(riE),.breakE(breakE),
		.syscallE(syscallE),.eretE(eretE),.cp0_writeE(cp0_writeE),
		.cp0_to_regE(cp0_to_regE),.is_mfcE(is_mfcE),
        .mfhiE(mfhiE),.mfloE(mfloE),

        .pcM(pcM),
        .aluoutM(aluoutM),
        .rt_valueM(rt_valueM),
        .writeregM(writeregM),.regwriteM(regwriteM),
        .instrM(instrM),
        .branchM(branchM),.pred_takeM(pred_takeM),.pc_branchM(pc_branchM),
        .overflowM(overflowM),
        .is_in_delayslot_iM(is_in_delayslot_iM),
        .rdM(rdM),
        .actual_takeM(actual_takeM),
		.mem_readM(mem_readM),.mem_writeM(mem_writeM),.memtoregM(memtoregM),
		.hilotoregM(hilotoregM),.riM(riM),.breakM(breakM),
		.syscallM(syscallM),.eretM(eretM),.cp0_writeM(cp0_writeM),
		.cp0_to_regM(cp0_to_regM),.is_mfcM(is_mfcM),
        .mfhiM(mfhiM),.mfloM(mfloM)
    );
    assign mem_addrM = aluoutM;     //访存地址
    assign mem_enM = (mem_readM  |  mem_writeM) & ~flush_exceptionM;; //意外刷新时需要
    // mem读写控制
    mem_control mem_control(
        .instrM(instrM),
        .addr(aluoutM),
    
        .data_wdataM(rt_valueM),    //原始的wdata
        .writedataM(writedataM),    //新的wdata
        .mem_write_selectM(mem_write_selectM),

        .mem_rdataM(mem_rdataM),    
        .data_rdataM(result_rdataM),

        .addr_error_sw(addrErrorSwM),
        .addr_error_lw(addrErrorLwM)  
    );
    wire hilo_write_re;
    assign hilo_write_re=hilo_writeE&~flush_exceptionM;//防止异常刷新时的错误写入

    // hilo寄存器
    hilo hilo(clk,rst,hilo_selectE,hilo_write_re,mfhiM,mfloM,aluoutE,hilo_outM);
    //后两位不为0
    assign pcErrorM = |(pcM[1:0] ^ 2'b00);  
    //在aluoutM, result_rdataM, hilo_outM, cp0_outW 中选择写入寄存器的数据
    mux4 #(32) mux4_memtoreg(aluoutM, result_rdataM, hilo_outM, cp0_outW, 
                            {hilotoregM, memtoregM} | {2{is_mfcM}},
                            resultM);
     //异常处理
    exception exception(
        .rst(rst),
        .ext_int(ext_int),
        //异常信号
        .ri(riM), .break_exception(breakM), .syscall(syscallM), .overflow(overflowM), 
        .addrErrorSw(addrErrorSwM), .addrErrorLw(addrErrorLwM), .pcError(pcErrorM), .eretM(eretM),
        //异常寄存器
        .cp0_status(cp0_statusW), .cp0_cause(cp0_causeW), .cp0_epc(cp0_epcW),
        //记录出错地址
        .pcM(pcM),
        .aluoutM(aluoutM),
        //输出异常处理信号
        .except_type(except_typeM),
        .flush_exception(flush_exceptionM),
        .pc_exception(pc_exceptionM),
        .pc_trap(pc_trapM),
        .badvaddrM(badvaddrM)
    );
     // cp0寄存
    cp0_reg cp0(
        .clk(clk),
        .rst(rst),
        .we_i(cp0_writeM),
        .i_cache_stall(i_cache_stall),
        .waddr_i(rdM),
        .raddr_i(rdM),
        .data_i(rt_valueM),
        .int_i(ext_int),
        
        .data_o(cp0_outW),

        .excepttype_i(except_typeM),
        .current_inst_addr_i(pcM),
        .is_in_delayslot_i(is_in_delayslot_iM),
        .bad_addr_i(badvaddrM),

        .status_o(cp0_statusW),
        .cause_o(cp0_causeW),
        .epc_o(cp0_epcW)
    );
    //分支预测结果
    assign pre_right = ~(pred_takeM ^ actual_takeM); 
    assign flush_pred_failedM = ~pre_right;
	//-------------------------------------Write_Back-------------------------------------------------
    
	Mem_WriteBack Me_Wr(
        .clk(clk),
        .rst(rst),
        .stallW(stallW),
        .flushW(flushW),

        .pcM(pcM),
        .aluoutM(aluoutM),
        .writeregM(writeregM),
        .regwriteM(regwriteM),
        .resultM(resultM),
        .flush_exceptionM(flush_exceptionM),
        


        .pcW(pcW),
        .aluoutW(aluoutW),
        .writeregW(writeregW),
        .regwriteW(regwriteW),
        .resultW(resultW),
        .flush_exceptionW(flush_exceptionW)
    );

	
	
	//hazard detection
	hazard hazard0(
        .i_cache_stall(i_cache_stall),
        .d_cache_stall(d_cache_stall),
        .alu_stallE(alu_stallE),

        .flush_jump_conflictE   (flush_jump_conflictE),
        .flush_pred_failedM     (flush_pred_failedM),
        .flush_exceptionM       (flush_exceptionM),

        .rsE(rsE),
        .rtE(rtE),
        .regwriteM(regwriteM),
        .regwriteW(regwriteW),
        .writeregM(writeregM),
        .writeregW(writeregW),
        .mem_readM(mem_readM),

        .stallF(stallF), .stallD(stallD), .stallE(stallE), .stallM(stallM), .stallW(stallW),
        .flushF(flushF), .flushD(flushD), .flushE(flushE), .flushM(flushM), .flushW(flushW),
        .longest_stall(longest_stall),
        .forward_1E(forward_1E), .forward_2E(forward_2E)
    );
	
endmodule
