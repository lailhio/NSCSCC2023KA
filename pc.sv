module pc_reg(  
    input clk,rst,stallF,
    input wire branchD,
    input wire branchM,
    input wire pre_right,
    input wire actual_takeM,
    input wire pred_takeD,

    input wire pc_trapM,   //是否发生异常
    input wire jump1D,
    input wire [31:0] pc_exceptionM,            //异常的跳转地址
    input wire [31:0] pcplus4E,              //预测跳，实际不跳 将pc_next指向branch指令的PC+8
    input wire [31:0] pc_branchM,              //预测不跳，实际跳转 将pc_next指向pc_branchD传到M阶段的值
    input wire [31:0] pc_jumpE,               //jump冲突，在E阶段 （E阶段rs的值）
    input wire [31:0] pc_jump1D,                 //D阶段jump不冲突跳转的地址（rs寄存器或立即数）
    input wire [31:0] pc_branchD,               //D阶段  预测跳转的跳转地址（PC+offset）
    input wire [31:0] PcPlus4F,
    input wire [31:0] PcPlus8F,
    output reg [31:0] pc
    );
    reg [31:0] next_pc;
    always @(*) begin
        if(pc_trapM) //发生异常
            next_pc = pc_exceptionM;
        else 
        if(branchM & ~pre_right & ~actual_takeM)  //预测跳  实际不挑
            next_pc = pcplus4E;
        else if(branchM & ~pre_right & actual_takeM)   //预测不跳  实际跳
            next_pc = pc_branchM;
        else if(jump1D) //jump不冲突
            next_pc = pc_jump1D;
        else if((~branchM  | branchM & pre_right) & branchD & pred_takeD) 
            //采用D阶段预测结果进行跳转
            next_pc = pc_branchD;
        else if(pc[2])
            next_pc = PcPlus4F;
        else
            next_pc = PcPlus8F;
    end

    always @(posedge clk) begin
        if(rst) begin
            pc<=32'hbfc0_0000; //起始地址
        end
        else if(~stallF) begin
            pc<=next_pc;
        end
    end
endmodule