module pc_reg(  
    input clk,rst,stallF,
    input wire branchD,
    input wire branchE,
    input wire pre_right,
    input wire actual_takeE,
    input wire pred_takeD,

    input wire pc_trapE,   //是否发生异常
    input wire jumpD,
    input wire [31:0] pc_exceptionE,            //异常的跳转地址
    input wire [31:0] PcPlus8E,              //预测跳，实际不跳 将pc_next指向branch指令的PC+8
    input wire [31:0] pc_branchE,              //预测不跳，实际跳转 将pc_next指向pc_branchD传到M阶段的值
    input wire [31:0] pc_jumpD,                 //D阶段jump不冲突跳转的地址（rs寄存器或立即数）
    input wire [31:0] pc_branchD,               //D阶段  预测跳转的跳转地址（PC+offset）
    input wire [31:0] PcPlus4F,                 //下一条指令的地址
    output reg [31:0] pc
    );
    wire [31:0] next_pc;
    assign next_pc = pc_trapE?pc_exceptionE:
                    pre_right?(jumpD?pc_jumpD:pred_takeD?pc_branchD:PcPlus4F):
                    actual_takeE?pc_branchE:PcPlus8E;

    always @(posedge clk) begin
        if(rst) begin
            pc<=32'hbfc0_0000; //起始地址
        end
        else if(~stallF) begin
            pc<=next_pc;
        end
    end
endmodule