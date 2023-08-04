module pc_reg(  
    input clk,rst,stallF,
    input wire branch1D, branch2D, 
    input wire branch1E, branch2E, 
    input wire pred_take1E, pred_take2E,
    input wire actual_take1E, actual_take2E, 
    input wire pred_take1D, pred_take2D,

    input wire pc_trapM,   //是否发生异常
    input wire jump1D, jump2D, 
    input wire [31:0] pc_exceptionM,            //异常的跳转地址
    input wire [31:0] PcPlus4E,              //预测跳，实际不跳 将pc_next指向branch指令的PC+8
    input wire [31:0] pc_branch1E, pc_branch2E,            //预测不跳，实际跳转 将pc_next指向pc_branchD传到M阶段的值
    input wire [31:0] pc_jump1D,                 //D阶段jump不冲突跳转的地址（rs寄存器或立即数）
    input wire [31:0] pc_branchD,               //D阶段  预测跳转的跳转地址（PC+offset）
    input wire [31:0] PcPlus4F,
    input wire [31:0] PcPlus8F,
    output reg [31:0] pc
    );
    reg [31:0] next_pc;
    // todo
    always @(*) begin
        if(pc_trapM) //发生异常
            next_pc = pc_exceptionM;
        else begin
            case({jump1D, jump2D, pred_take1D, pred_take2D, pred_take1E, pred_take2E, actual_take1E, actual_take2E})
                8'b00000000: next_pc = PcPlus8F; 
                8'b10000000, 8'b10001010: next_pc = pc_jump1D;
                8'b01000000, 8'b01001010, 8'b01000101: next_pc = pc_jump2D;
                8'b10000010, 8'b01000010, 8'b00100010, 8'b00010010, 8'b00000010: next_pc = pc_branch1E;
                8'b01000001, 8'b00100001, 8'b00010001, 8'b00000001: next_pc = pc_branch2E;
                8'b10000001, 8'b01000001, 8'b00100001, 8'b00010001, 8'b00000001: next_pc = pc_branch2E;
            endcase
        end
        if(~pre_rightE) begin
            if(actual_take1E) //pred 0. actual 1
`               next_pc = pc_branch1E;
            else if(actual_take2E)
                next_pc = pc_branch2E;
            else if(~actual_take2E)
                next_pc = pc_branch2E;
        end
            
        else if(branchM & ~pre_rightE & actual_takeE)   
            next_pc = pc_branchM;
        else if(jump1D) //jump不冲突
            
        else if((~branchM  | branchM & pre_rightE) & branchD & pred_take1D) 
            //采用D阶段预测结果进行跳转
            next_pc = pc_branchD;
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