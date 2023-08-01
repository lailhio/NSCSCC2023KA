`include "defines2.vh"
module BranchPredict(
    input wire clk, rst,
    
    input wire flushD,
    input wire stallD,

    input wire [31:0] instrD,
    input wire [31:0] immD,

    input wire [31:0] PcF2,
    input wire [31:0] pcE,
    input wire branchE,
    input wire actual_takeE,

    output wire branchD,
    output wire pred_takeD
);
    wire pred_takeF;
    reg pred_takeF_r;
    wire [5:0] op_code, funct;
    wire [4:0] rs, rt;
    assign op_code = instrD[31:26];
	assign rs = instrD[25:21];
	assign rt = instrD[20:16];
	assign funct = instrD[5:0];
    assign branchD = ( (~|(op_code ^ `REGIMM_INST)) & (~|(instrD[19:17] ^ 3'b000) | (~|(instrD[19:17] ^ 3'b001))) ) //6'b000001 = EXE_REGIMM
                    | (~|(op_code[5:2] ^ 4'b0001)); //4'b0001 -> beq, bgtz, blez, bne
                                                    // 3'b000 -> BLTZ BLTZAL BGEZAL BGEZ
                                                    // 3'b001 -> BGEZALL BGEZL BLTZALL BLTZL

    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    integer i,j;
    wire [(PHT_DEPTH-1):0] PHT_index;
    wire [(BHT_DEPTH-1):0] BHT_index;
    wire [(PHT_DEPTH-1):0] BHR_value;

    assign BHT_index = PcF2[11:2];     
    assign BHR_value = BHT[BHT_index];  
    assign PHT_index = BHR_value;

    assign pred_takeF = PHT[PHT_index][1];

// ---------------------------------------BHT初始化以及更新---------------------------------------
    wire [(PHT_DEPTH-1):0] update_PHT_index;
    wire [(BHT_DEPTH-1):0] update_BHT_index;
    wire [(PHT_DEPTH-1):0] update_BHR_value;

    assign update_BHT_index = pcE[11:2];     
    assign update_BHR_value = BHT[update_BHT_index];  
    assign update_PHT_index = update_BHR_value;

    always@(posedge clk) begin
        if(rst) begin
            BHT <= '{default:'0};
        end
        else if(branchE) begin
            BHT[update_BHT_index] <= {BHT[update_BHT_index] << 1, actual_takeE};
        end
    end
// ---------------------------------------BHT初始化以及更新---------------------------------------

// ---------------------------------------PHT初始化以及更新---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            PHT = '{default:'0};
        end
        else begin
            case(PHT[update_PHT_index])
                Strongly_not_taken  :   PHT[update_PHT_index] <= actual_takeE & branchE ? Weakly_not_taken : Strongly_not_taken;
                Weakly_not_taken    :   PHT[update_PHT_index] <= actual_takeE & branchE ? Weakly_taken : Strongly_not_taken;
                Weakly_taken        :   PHT[update_PHT_index] <= actual_takeE & branchE ? Strongly_taken : Weakly_not_taken;
                Strongly_taken      :   PHT[update_PHT_index] <= actual_takeE & branchE ? Strongly_taken : Weakly_taken;
            endcase 
        end
    end
// ---------------------------------------PHT初始化以及更新---------------------------------------

// --------------------------pipeline------------------------------
    always @(posedge clk) begin
        if(rst | flushD) begin
            pred_takeF_r <= 0;
        end
        else if(~stallD) begin
            pred_takeF_r <= pred_takeF;
        end
    end
// --------------------------pipeline------------------------------

    assign pred_takeD = branchD & pred_takeF_r;    // 为branch指令且预测跳转

endmodule