`timescale 1ns / 1ps



module datapath(

	input wire clk,rst,
	
	input wire  [5 :0] ext_int, //异常处理
    
    //inst
    output wire [31:0] inst_addrF,  //指令地址
    output wire        inst_enF,  //使能
    input wire  [31:0] instrF,  //注：instr ram时钟取反

    //data
    output wire mem_enM,                    
    output wire [31:0] mem_addrM,     //�?/写地�?
    input  wire [31:0] mem_rdataM,    //读数�?
    output wire [3 :0] mem_wenM,      //写使�?
    output wire [31:0] writedataM,    //写数�?
    input wire         d_cache_stall
	//debug interface
//    output wire[31:0] debug_wb_pc,
//    output wire[3:0] debug_wb_rf_wen,
//    output wire[4:0] debug_wb_rf_wnum,
//    output wire[31:0] debug_wb_rf_wdata
    );
	
	//--------fetch stage----------
	wire [31:0] pcF, pc_next, pc_plus4F;    //pc
    wire [31:0] instrF_4;                   //instrF末尾�?2'b00
    
    wire pc_errorF;  // pc错误

    wire F_change; // 此时的D阶段（即上一条指令）是否为跳转指�?
    // wire pcerrorD, pcerrorE, pcerrorM; 
	//----------decode stage---------
	wire[3:0] aluopD;
	wire[4:0] alucontrolD;
	 wire [31:0] instrD;  //指令
    wire [4 :0] rsD, rtD, rdD, saD;  //rs rt rd 寄存器标�?
    wire [31:0] pcD, pc_plus4D;  //pc

    wire [31:0] rd1D, rd2D, immD, pc_branchD, pc_jumpD;  //寄存器读出数�? 立即�? pc分支 跳转
    wire        pred_takeD, branchD, jumpD;  //立即数扩�? 分支预测 branch jump信号
    wire        flush_pred_failedM;  //分支预测失败

    wire        jump_conflictD;  //jump冲突
    wire [4 :0] branch_judge_controlD; //分支判断控制
	wire 		sign_exD;          //立即数是否为符号扩展
	wire [1:0] 	regdstD;    	//写寄存器选择  00-> rd, 01-> rt, 10-> �?$ra
	wire 		is_immD;       //alu srcb选择 0->rd2E, 1->immE
	wire 		regwriteD;//写寄存器堆使�?
	wire 		hilo_wenD;
	wire 		mem_readD, mem_writeD;
	wire 		memtoregD;       	//result选择 0->aluout, 1->read_data
	wire 		hilo_to_regD;			// 00--aluoutM; 01--hilo_o; 10 11--rdataM;
	wire 		riD;
	wire 		breakD, syscallD, eretD;
	wire 		cp0_wenD;
	wire 		cp0_to_regD;
	wire		is_mfcD;
    
    wire        is_in_delayslot_iD;//指令是否在延迟槽
	//-------execute stage----------
	wire [31:0] pcE, pc_plus4E ,rd1E, rd2E, mem_wdataE, immE; //pc pc+4 寄存器�?? 写内存�?? 立即�?
    wire [4 :0] rsE, rtE, rdE, saE;  //寄存器号
    wire        pred_takeE;  //分支预测
    wire [1 :0] regdstE;  //写回选择信号, 00-> rd, 01-> rt, 10-> �?$ra
    wire [4 :0] alucontrolE;  //alu控制信号

    wire [31:0] src_aE, src_bE; //alu输入（操作数
    wire [63:0] aluoutE; //alu输出
    wire        is_immE;  //alu srcb选择 0->rd2E, 1->immE
    wire [4 :0] writeregE; //写寄存器�?
    wire        branchE; //分支信号
    wire [31:0] pc_branchE;  //分支跳转pc

    wire [31:0] instrE;
    wire [31:0] pc_jumpE;  //jump pc
    wire        jump_conflictE; //jump冲突
    wire        regwriteE;	//寄存器写
    wire        alu_stallE;  //alu暂停
    wire [31:0] rs_valueE, rt_valueE;  //rs rt寄存器的�?
    
    wire        flush_jump_conflictE;  //jump冲突
    wire        jumpE; //jump信号
    wire        actual_takeE;  //分支预测 实际结果
    wire [4 :0] branch_judge_controlE; //分支判断控制
	wire        memtoregE, mem_readE, mem_writeE;
	wire        hilo_to_regE;
	wire        breakE, syscallE,is_mfc;
	wire        riE;
	wire        cp0_wenE;
	wire        cp0_to_regE;
	wire 		is_mfcE;
	wire        hilo_wenE;  //hilo写使�?
 // 异常处理信号
    wire        is_in_delayslot_iE; //是否处于延迟�?
    wire        overflowE; //溢出
	
	//----------mem stage--------
	wire [31:0] pcM;  // pc
    wire [31:0] aluoutM; //alu输出
    wire [4:0] 	writeregM; //写寄存器�?
    wire [31:0] instrM;  //指令
    wire        mem_readM; //读内�?
    wire        mem_writeM; //写内�?
    wire        regwriteM;  //寄存器写
    wire        memtoregM;  //写回寄存器�?�择信号
    wire [31:0] resultM;  // mem out
    wire        actual_takeM;  //分支预测 真实结果
    wire        pre_right;  // 预测正确
    wire        pred_takeM; // 预测
    wire        branchM; // 分支信号
    wire [31:0] pc_branchM; //分支跳转地址

    wire [31:0] mem_ctrl_rdataM;
    wire [31:0] writedataM_temp;
    wire [31:0] mem_ctrl_rdataM;
    wire [63:0] hilo_oM;  //hilo输出
    wire        hilo_to_regM; 
	wire		is_mfcM;

    wire [4:0] 	rdM;
    wire [31:0] rt_valueM;
    //异常处理信号 exception
    wire        riM;  //指令不存�?
    wire        breakM; //break指令
    wire        syscallM; //syscall指令
    wire        eretM; //eretM指令
    wire        overflowM;  //算数溢出
    wire        addrErrorLwM, addrErrorSwM; //访存指令异常
    wire        pcErrorM;  //pc异常

	// cp0	
    wire [31:0] except_typeM;  // 异常类型
    wire [31:0] cp0_statusM;  //status�?
    wire [31:0] cp0_causeM;  //cause�?
    wire [31:0] cp0_epcM;  //epc�?
    wire        flush_exceptionM;  // 发生异常时需要刷新流水线
    wire [31:0] pc_exceptionM; //异常处理的地�?0xbfc0_0380，若为eret指令 则为返回地址
    wire        pc_trapM; // 发生异常时pc特殊处理
    wire [31:0] badvaddrM;
    wire        is_in_delayslot_iM;
    wire        cp0_to_regM;
    wire        cp0_wenM;
    
	//------writeback stage----------
	wire memtoregW;
	wire [4:0] writeregW;//写寄存器�?
	wire regwriteW;
	wire [31:0] aluoutW,resultW;
	wire [31:0] pcW;

    wire [31:0] cp0_statusW, cp0_causeW, cp0_epcW, cp0_data_oW;
//-----------------Data------------------------------------------
	//--------------------debug---------------------
//    assign debug_wb_pc          = pcplus4D;
//    assign debug_wb_rf_wen      = {4{writeregM & ~flushE }};
//    assign debug_wb_rf_wnum     = writeregM;
//    assign debug_wb_rf_wdata    = resultW;

    //------------------Fetch-------------------------
    assign inst_addrF = pcF; //F阶段地址
    assign inst_enF = ~stallF & ~pc_errorF & ~flush_pred_failedM; // 指令读使能：�?切正�?
    assign pc_errorF = pcF[1:0] == 2'b0 ? 1'b0 : 1'b1; //pc�?后两位不�?0 则pc错误
    // pc+4
    assign pc_plus4F = pcF + 4;
    // pc reg
    pc_reg pc_reg0(
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
        .pc_plus4E(pc_plus4E),
        .pc_branchM(pc_branchM),
        .pc_jumpE(pc_jumpE),
        .pc_jumpD(pc_jumpD),
        .pc_branchD(pc_branchD),
        .pc_plus4F(pc_plus4F),

        .pc(pcF)
    );

    assign instrF_4 = ({32{~(|(pcF[1:0] ^ 2'b00))}} & instrF);  //�?2位一定为00 不为0则inst�?0
    assign F_change = branchD | jumpD; //F阶段得到此时d阶段是否为跳转指�?

	//------------------Decode-------------------------

    Fetch_Decode Fe_De(
        .clk(clk), .rst(rst),
        .stallD(stallD),
        .flushD(flushD),

        .pcF(pcF),
        .pc_plus4F(pc_plus4F),
        .instrF(instrF_4),
        .F_change(F_change), //上一条指令是跳转
        
        .pcD(pcD),
        .pc_plus4D(pc_plus4D),
        .instrD(instrD),
        .is_in_delayslot_iD(is_in_delayslot_iD)  //处于延迟�?
    );

	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];
	aludec ad(funct,aluopD,alucontrol);
	maindec md(
		instrD,
		//output
		sign_exD,
		regdstD,is_immD,regwriteD,hilo_wenD,

		mem_readD, mem_writeD,
		memtoregD,
		hilo_to_regD,riD,
		breakD, syscallD, eretD, 
		cp0_wenD,
		cp0_to_regD,
		is_mfcD,   //为mfc0
		aluopD,
		branch_judge_controlD
		);
    //扩展立即�?
    signext signex(sign_exD,instrD[15:0],immD);
	//regfile (operates in decode and writeback)
	regfile rf(clk,stallW,regwriteW,rsD,rtD,writeregW,resultW,rd1D,rd2D);
    // 分支跳转  立即数左�?2 + pc+4   
    assign pc_branchD = {immD[29:0], 2'b00} + pc_plus4D;

	//分支预测�?
    BranchPredict branch_predict0(
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
        .branchL_D(),
        .pred_takeD(pred_takeD)
    );
    // jump指令控制
    jump_control jump_control(
        .instrD(instrD),
        .pc_plus4D(pc_plus4D),
        .rd1D(rd1D),
        .regwriteE(regwriteE), .regwriteM(regwriteM),
        .writeregE(writeregE), .writeregM(writeregM),

        .jumpD(jumpD),                      //是jump类指�?(j, jr)
        .jump_conflictD(jump_conflictD),    //jr rs寄存器发生冲�?
        .pc_jumpD(pc_jumpD)                 //D阶段�?终跳转地�?
    );
	//-----------Execute----------------
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
        .pc_plus4D(pc_plus4D),
        .instrD(instrD),
        .branchD(branchD),
        .pred_takeD(pred_takeD),
        .pc_branchD(pc_branchD),
        .jump_conflictD(jump_conflictD),
        .is_in_delayslot_iD(is_in_delayslot_iD),
        .saD(saD),
        .alucontrolD(alucontrolD),
        .jumpD(jumpD),
        .branch_judge_controlD(branch_judge_controlD),
		.regdstD(regdstD),
		.is_immD(is_immD),.regwriteD(regwriteD),.hilo_wenD(hilo_wenD),
		.mem_readD(mem_readD),.mem_writeD(mem_writeD),.memtoregD(memtoregD),
		.hilo_to_regD(hilo_to_regD),.riD(riD),.breakD(breakD),
		.syscallD(syscallD),.eretD(eretD),.cp0_wenD(cp0_wenD),
		.cp0_to_regD(cp0_to_regD),.is_mfcD(is_mfcD),
	//Execute stage
        .pcE(pcE),
        .rsE(rsE), .rd1E(rd1E), .rd2E(rd2E),
        .rtE(rtE), .rdE(rdE),
        .immE(immE),
        .pc_plus4E(pc_plus4E),
        .instrE(instrE),
        .branchE(branchE),
        .pred_takeE(pred_takeE),
        .pc_branchE(pc_branchE),
        .jump_conflictE(jump_conflictE),
        .is_in_delayslot_iE(is_in_delayslot_iE),
        .saE(saE),
        .alucontrolE(alucontrolE),
        .jumpE(jumpE),
        .branch_judge_controlE(branch_judge_controlE),
		.regdstE(regdstE),
		.is_immE(is_immE),.regwriteE(regwriteE),.hilo_wenE(hilo_wenE),
		.mem_readE(mem_readE),.mem_writeE(mem_writeE),.memtoregE(memtoregE),
		.hilo_to_regE(hilo_to_regE),.riE(riE),.breakE(breakE),
		.syscallE(syscallE),.eretE(eretE),.cp0_wenE(cp0_wenE),
		.cp0_to_regE(cp0_to_regE),.is_mfcE(is_mfcE)
    );
	//ALU
    ALU alu0(
        .clk(clk),
        .rst(rst),
        .flushE(flushE),
        .src_aE(src_aE), .src_bE(src_bE),
        .alucontrolE(alucontrolE),
        .sa(saE),
        .hilo(hilo_oM),

        .div_stallE(alu_stallE),
        .aluoutE(aluoutE),
        .overflowE(overflowE)
    );

    mux4 #(5) mux4_regdst(
        rdE,rtE,5'd31,5'b0,
        regdstE, 
        writeregE //选择writeback寄存�?
    );

    mux4 #(32) mux4_forward_1E(
        rd1E,resultM,resultW,pc_plus4D,     // 执行jalr，jal指令；写入到$ra寄存器的数据（跳转指令对应延迟槽指令的下�?条指令的地址即PC+8�? 
                                             //可以保证延迟槽指令不会被flush，故plush_4D存在
        {2{jumpE | branchE}} | forward_1E,  // 当ex阶段是jal或�?�jalr指令，或者bxxzal时，jumpE | branchE== 1；�?�择pc_plus4D；其他时候为数据前推
        src_aE
    );
    mux4 #(32) mux4_forward_2E(
        rd2E,resultM,resultW,immE,                               //立即�?
        {2{is_immE}} | forward_2E,     //main_decoder产生is_immE信号，表示alu第二个操作数为立即数
        src_bE
    );
    mux4 #(32) mux4_rs_valueE(rd1E, resultM, resultW, 32'b0, forward_1E, rs_valueE); //数据前推后的rs寄存器的�?
    mux4 #(32) mux4_rt_valueE(rd2E, resultM, resultW, 32'b0, forward_2E, rt_valueE); //数据前推后的rt寄存器的�?

	//计算branch结果 得到真实是否跳转
    branch_check branch_check(
        .branch_judge_controlE(branch_judge_controlE),
        .src_aE(rs_valueE),
        .src_bE(rt_valueE),
        .actual_takeE(actual_takeE)
    );
    assign pc_jumpE = rs_valueE; //jr指令 跳转到rs的�??
    assign flush_jump_confilctE = jump_conflictE;
	//-------------Mem---------------------
	
	Execute_Mem Ex_Me(
        .clk(clk),
        .rst(rst),
        .stallM(stallM),
        .flushM(flushM),

        .pcE(pcE),
        .aluoutE(aluoutE),
        .rt_valueE(rt_valueE),
        .writeregE(writeregE),
        .instrE(instrE),
        .branchE(branchE),
        .pred_takeE(pred_takeE),
        .pc_branchE(pc_branchE),
        .overflowE(overflowE),
        .is_in_delayslot_iE(is_in_delayslot_iE),
        .rdE(rdE),
        .actual_takeE(actual_takeE),
		.mem_readE(mem_readE),.mem_writeE(mem_writeE),.memtoregE(memtoregE),
		.hilo_to_regE(hilo_to_regE),.riE(riE),.breakE(breakE),
		.syscallE(syscallE),.eretE(eretE),.cp0_wenE(cp0_wenE),
		.cp0_to_regE(cp0_to_regE),.is_mfcE(is_mfcE),

        .pcM(pcM),
        .aluoutM(aluoutM),
        .rt_valueM(rt_valueM),
        .writeregM(writeregM),
        .instrM(instrM),
        .branchM(branchM),
        .pred_takeM(pred_takeM),
        .pc_branchM(pc_branchM),
        .overflowM(overflowM),
        .is_in_delayslot_iM(is_in_delayslot_iM),
        .rdM(rdM),
        .actual_takeM(actual_takeM),
		.mem_readM(mem_readM),.mem_writeM(mem_writeM),.memtoregM(memtoregM),
		.hilo_to_regM(hilo_to_regM),.riM(riM),.breakM(breakM),
		.syscallM(syscallM),.eretM(eretM),.cp0_wenM(cp0_wenM),
		.cp0_to_regM(cp0_to_regM),.is_mfcM(is_mfcM)
    );
    assign mem_addrM = alu_outM;
    assign mem_enM = (mem_readM  |  mem_writeM) ; //读或者写
    // mem读写控制
    mem_control mem_control(
        .instrM(instrM),
        .addr(aluoutM),
    
        .data_wdataM(rt_valueM),    //原始的wdata
        .writedataM(writedataM),    //新的wdata
        .mem_wenM(mem_wenM),

        .mem_rdataM(mem_rdataM),    
        .data_rdataM(mem_ctrl_rdataM),

        .addr_error_sw(addrErrorSwM),
        .addr_error_lw(addrErrorLwM)  
    );
    // hilo寄存�?
    hilo hilo(clk,rst,instrM,hilo_wenE&flush_exceptionM,aluoutE,hilo_oM);
    assign pcErrorM = |(pcM[1:0] ^ 2'b00);  //后两位不�?00
     //异常处理
    exception exception(
        .rst(rst),
        .ext_int(ext_int),
        .ri(riM), .break(breakM), .syscall(syscallM), .overflow(overflowM), .addrErrorSw(addrErrorSwM), .addrErrorLw(addrErrorLwM), .pcError(pcErrorM), .eretM(eretM),
        .cp0_status(cp0_statusW), .cp0_cause(cp0_causeW), .cp0_epc(cp0_epcW),
        .pcM(pcM),
        .alu_outM(alu_outM),

        .except_type(except_typeM),
        .flush_exception(flush_exceptionM),
        .pc_exception(pc_exceptionM),
        .pc_trap(pc_trapM),
        .badvaddrM(badvaddrM)
    );
     // cp0寄存�?
    cp0_reg cp0(
        .clk(clk),
        .rst(rst),
        .en(flush_exceptionM),
        .we_i(cp0_wenM),
        .waddr_i(rdM),
        .raddr_i(rdM),
        .data_i(rt_valueM),
        .int_i(ext_int),
        
        .data_o(cp0_data_oW),

        .except_type_i(except_typeM),
        .current_inst_addr_i(pcM),
        .is_in_delayslot_i(is_in_delayslot_iM),
        .badvaddr_i(badvaddrM),

        .status_o(cp0_statusW),
        .cause_o(cp0_causeW),
        .epc_o(cp0_epcW)
    );
	//---------Write_Back----------------
    //在alu_outM, mem_ctrl_rdataM, hilo_oM, cp0_data_oW中�?�择写入寄存器的�?
    mux4 #(32) mux4_memtoreg(alu_outM, mem_ctrl_rdataM, hilo_oM, cp0_data_oW, 
                            {hilo_to_regM, mem_to_regM} | {2{is_mfcM}},
                            resultM);
    //分支预测结果
    assign pre_right = ~(pred_takeM ^ actual_takeM); 
    assign flush_pred_failedM = ~pre_right;
	Mem_WriteBack Me_Wr(
        .clk(clk),
        .rst(rst),
        .stallW(stallW),

        .pcM(pcM),
        .aluoutM(aluoutM),
        .writeregM(writeregM),
        .regwriteM(regwriteM),
        .resultM(resultM),


        .pcW(pcW),
        .aluoutW(aluoutW),
        .writeregW(writeregW),
        .regwriteW(regwriteW),
        .resultW(resultW)
    );

	
	
	//hazard detection
	hazard hazard0(
        .d_cache_stall(d_cache_stall),
        .alu_stallE(alu_stallE),

        .flush_jump_confilctE   (flush_jump_confilctE),
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
        .forward_1E(forward_1E), .forward_2E(forward_2E)
    );
	
endmodule
