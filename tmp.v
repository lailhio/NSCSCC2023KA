
	wire [31:0] pcplus4F;    //pc
    wire [31:0] instrF_4;                   //instrF末尾为2'b00
    
    wire pc_errorF;  // pc错误

    wire is_in_delayslot_iF; // 此时的D阶段（即上一条指令）是否为跳转指令