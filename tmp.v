//----------decode stage---------
	wire[3:0] aluopD;
	wire[4:0] alucontrolD;
	 wire [31:0] instrD;  //指令
    wire [4 :0] rsD, rtD, rdD, saD;  //rs rt rd 寄存器号
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