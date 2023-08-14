module pc_reg(  
    input clk,rst,stallF,
    input wire pred_take1E, pred_take2E,
    input wire actual_take1E, actual_take2E, 
    input wire pred_take1D, pred_take2D,

    input wire pc_trap1M, pc_trap2M,  //是否发生异常
    input wire jump1D, jump2D, 
    input wire [31:0] pc_exception1M, pc_exception2M,           //异常的跳转地址
    input wire [31:0] pc_branch1E, pc_branch2E,            //预测不跳，实际跳转 将pc_next指向pc_branchD传到M阶段的值
    input wire [31:0] pc_jump1D, pc_jump2D,     //D阶段jump不冲突跳转的地址（rs寄存器或立即数）
    input wire [31:0] pc_branch1D, pc_branch2D,              //D阶段  预测跳转的跳转地址（PC+offset）
    input wire [31:0] PcNextF, Pc1Plus8E, Pc2Plus8E,
    output reg [31:0] pc
    );
    reg [31:0] next_pc;
    // todo
    always @(*) begin
        if(pc_trap1M) //发生异常
            next_pc = pc_exception1M;
        else if(pc_trap2M)
            next_pc = pc_exception2M;
        else begin
            case({jump1D, jump2D, pred_take1D, pred_take2D, pred_take1E, pred_take2E, actual_take1E, actual_take2E})
                8'b00000000: next_pc = PcNextF; 
                8'b10000000, 8'b10001010: next_pc = pc_jump1D; // E1
                8'b01000000, 8'b01001010, 8'b01000101: next_pc = pc_jump2D; //E1 right, E2 right
                8'b10000010, 8'b01000010, 8'b00100010, 8'b00010010, 8'b00000010: next_pc = pc_branch1E; // D1, D2 Not Valid. E1 wrong
                8'b01000001, 8'b00010001, 8'b00000001: next_pc = pc_branch2E;  // D2 Not Valid. E2 wrong
                8'b00100000, 8'b00101010: next_pc = pc_branch1D; // E1 Right & Pred1
                8'b00010000, 8'b00011010, 8'b00010101: next_pc = pc_branch2D; // E1 E2 right & Pred2
                8'b10001000, 8'b01001000, 8'b00101000, 8'b00011000, 8'b00001000: next_pc = Pc1Plus8E; // D1, D2 Not Valid. E1 wrong
                8'b01000100, 8'b00010100, 8'b00000100: next_pc = Pc2Plus8E;  // D2 Not Valid. E2 wrong
                default : next_pc = PcNextF; 
            endcase
        end
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