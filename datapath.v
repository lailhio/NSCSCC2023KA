`timescale 1ns / 1ps



module datapath(

	input wire clk,rst,
	
	input wire[31:0] instrF,
	
	
	output wire flushE,
	
	output wire[31:0] aluoutM,writedataM
	//debug interface
//    output wire[31:0] debug_wb_pc,
//    output wire[3:0] debug_wb_rf_wen,
//    output wire[4:0] debug_wb_rf_wnum,
//    output wire[31:0] debug_wb_rf_wdata
    );
	
	//--------fetch stage----------
	wire [31:0] pcF, pc_next, pc_plus4F;    //pc
    wire [31:0] instrF_4;                   //instrF末尾为2'b00
    
    wire pc_errorF;  // pc错误
    wire pcerrorD, pcerrorE, pcerrorM; 

    wire F_change; // 此时的D阶段（即上一条指令）是否为跳转指令
// wire pcerrorD, pcerrorE, pcerrorM; 
	//----------decode stage---------
	wire[3:0] aluopD;
	wire[4:0] alucontrolD;
	 wire [31:0] instrD;  //指令
    wire [4 :0] rsD, rtD, rdD, saD;  //rs rt rd 寄存器标号
    wire [31:0] pcD, pc_plus4D;  //pc

    wire [31:0] rd1D, rd2D, immD, pc_branchD, pc_jumpD;  //寄存器读出数据 立即数 pc分支 跳转
    wire        sign_exD, pred_takeD, branchD, jumpD;  //立即数扩展 分支预测 branch jump信号
    wire        flush_pred_failedM;  //分支预测失败

    wire        jump_conflictD;  //jump冲突
    wire [4 :0] branch_judge_controlD; //分支判断控制
	wire 		sign_exD;          //立即数是否为符号扩展
	wire [1:0] 	regdstD;    	//写寄存器选择  00-> rd, 01-> rt, 10-> 写$ra
	wire 		is_immD;       //alu srcb选择 0->rd2E, 1->immE
	wire 		regwriteD;//写寄存器堆使能
	wire 		hilo_wenD;
	wire 		mem_readD, mem_writeD;
	wire 		memtoregD;       	//result选择 0->alu_out, 1->read_data
	wire 		hilo_to_regD;			// 00--alu_outM; 01--hilo_o; 10 11--rdataM;
	wire 		riD;
	wire 		breakD, syscallD, eretD;
	wire 		cp0_wenD;
	wire 		cp0_to_regD;
	wire		is_mfcD;
    
    wire  is_in_delayslot_iD;//指令是否在延迟槽
	//-------execute stage----------
	wire [31:0] pcE, pc_plus4E ,rd1E, rd2E, mem_wdataE, immE; //pc pc+4 寄存器值 写内存值 立即数
    wire [4 :0] rsE, rtE, rdE, saE;  //寄存器号
    wire        pred_takeE;  //分支预测
    wire [1 :0] regdstE;  //写回选择信号, 00-> rd, 01-> rt, 10-> 写$ra
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
    wire [31:0] rs_valueE, rt_valueE;  //rs rt寄存器的值
    
    wire        flush_jump_confilctE;  //jump冲突
    wire        jumpE; //jump信号
    wire        actual_takeE;  //分支预测 实际结果
    wire [4 :0] branch_judge_controlE; //分支判断控制
	wire        memtoregE, mem_readE, mem_writeE;
	wire        hilo_to_regE;
	wire        breakE, syscallE;is_mfc
	wire        riE;
	wire        cp0_wenE;
	wire        cp0_to_regE;
	wire 		is_mfcE;
	wire        hilo_wenE;  //hilo写使能
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

    wire [31:0] mem_ctrl_rdataM;
    wire [31:0] mem_wdataM_temp;
    wire [31:0] mem_ctrl_rdataM;
    wire [63:0] hilo_oM;  //hilo输出
    wire        hilo_to_regM; 
	wire		is_mfcM;

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
    wire [31:0] cp0_statusM;  //status值
    wire [31:0] cp0_causeM;  //cause值
    wire [31:0] cp0_epcM;  //epc值
    wire        flush_exceptionM;  // 发生异常时需要刷新流水线
    wire [31:0] pc_exceptionM; //异常处理的地址0xbfc0_0380，若为eret指令 则为返回地址
    wire        pc_trapM; // 发生异常时pc特殊处理
    wire [31:0] badvaddrM;
    wire        is_in_delayslot_iM;
    wire        cp0_to_regM;
    wire        cp0_wenM;
    
	//------writeback stage----------
	wire memtoregW;
	wire [4:0] writeregW;//写寄存器号
	wire regwriteW;
	wire [31:0] aluoutW,resultW;
	wire [31:0] pcW;

    wire [31:0] cp0_statusW, cp0_causeW, cp0_epcW, cp0_data_oW;
//-----------------Data--------------------

	

	//-----------Decode----------------
	assign opD = instrD[31:26];
	assign functD = instrD[5:0];
	assign rsD = instrD[25:21];
	assign rtD = instrD[20:16];
	assign rdD = instrD[15:11];
	assign saD = instrD[10:6];
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
		aluopD
		);
	aludec ad(funct,aluopD,alucontrol);

	assign pcsrcD = branchD & equalD;
	//regfile (operates in decode and writeback)
	regfile rf(clk,regwriteW,rsD,rtD,writeregW,resultW,srcaD,srcbD);

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
        .is_in_delayslot_iD(is_in_delayslot_iD)  //处于延迟槽
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
        .branch_judge_controlE(branch_judge_controlE)      
    );
	//-------------Mem---------------------
	Execute_Mem Ex_Me(
		clk,rst,
		srcb2E,aluoutE,writeregE,
		memtoregE,memwriteE,regwriteE,
		fcE,
		writedataM2,aluoutM,writeregM,
		memtoregM,memwriteM,regwriteM,
    	fcM
    );
	//---------Write_Back----------------
	Mem_WriteBack Me_Wr(
		clk,rst,
		aluoutM,readdataM,writeregM,
		memtoregM,regwriteM,
		fcM,
		aluoutW,readdataW,writeregW,
		memtoregW,regwriteW,
		fcW
    );
	
	wire [31:0] readdataWB;
	reg[31:0] readtempW = 32'b0;
	//mem stage
	wire [31:0] writedataM2;
	reg [31:0] writetempM = 32'b0;
	
	
	//hazard detection
	hazard h(
		//fetch stage
		stallF,
		//decode stage
		rsD,rtD,
		branchD,
		forwardaD,forwardbD,
		stallD,
		//execute stage
		rsE,rtE,
		writeregE,
		regwriteE,
		memtoregE,
		forwardaE,forwardbE,
		flushE,
		//mem stage
		writeregM,
		regwriteM,
		memtoregM,
		//write back stage
		writeregW,
		regwriteW
		);

	//--------------------debug---------------------
//    assign debug_wb_pc          = pcplus4D;
//    assign debug_wb_rf_wen      = {4{regwriteM & ~flushE }};
//    assign debug_wb_rf_wnum     = regwriteM;
//    assign debug_wb_rf_wdata    = resultW;


	//next PC logic (operates in fetch an decode)
	mux2 #(32) pcbrmux(pcplus4F,pcbranchD,pcsrcD,pcnextbrFD);
	mux2 #(32) pcmux(pcnextbrFD,
		{pcplus4D[31:28],instrD[25:0],2'b00},
		jumpD,pcnextFD);

	

	//fetch stage logic
	pc #(32) pcreg(clk,rst,~stallF,pcnextFD,pcF);
	adder pcadd1(pcF,32'b100,pcplus4F);

	signext se(alusrcE,instrD[15:0],signimmD);
	sl2 immsh(signimmD,signimmshD);
	adder pcadd2(pcplus4D,signimmshD,pcbranchD);
	mux2 #(32) forwardamux(srcaD,aluoutM,forwardaD,srca2D);
	mux2 #(32) forwardbmux(srcbD,aluoutM,forwardbD,srcb2D);
	eqcmp comp(srca2D,srcb2D,equalD);


	mux3 #(32) forwardaemux(srcaE,resultW,aluoutM,forwardaE,srca2E);
	mux3 #(32) forwardbemux(srcbE,resultW,aluoutM,forwardbE,srcb2E);
	mux2 #(32) srcbmux(srcb2E,signimmE,alusrcE,srcb3E);
	alu alu(srca2E,srcb3E,saE,alucontrolE,aluoutE);
	mux2 #(5) wrmux(rtE,rdE,regdstE,writeregE);

    //writedata
    
	
	//read data 
endmodule
