`include "defines2.vh"
`timescale 1ns / 1ps
module BranchPredict(
    input wire clk, rst,
    
    input wire flush_masterD,
    input wire stall_masterD,
    input wire flush_slaveD,
    input wire stall_slaveD,

    input wire [31:0] instr1D, instr2D, 

    input wire [31:0] PcF2, PcPlus4F2, 
    input wire [31:0] pcE, PcPlus4E, 
    input wire branch1E, branch2E, 
    input wire actual_take1E, actual_take2E,

    output wire branch1D, branch2D, 
    output wire pred_take1D, pred_take2D
);
    wire pred_take1F2, pred_take2F2;
    reg pred_take1D_r, pred_take2D_r;

    assign branch1D = ( (~|(instr1D[31:26] ^ `REGIMM_INST)) & (~|(instr1D[19:17] ^ 3'b000) | (~|(instr1D[19:17] ^ 3'b001))) ) 
                    | (~|(instr1D[31:26][5:2] ^ 4'b0001)); //4'b0001 -> beq, bgtz, blez, bne
                                                    // 3'b000 -> BLTZ BLTZAL BGEZAL BGEZ
                                                    // 3'b001 -> BGEZALL BGEZL BLTZALL BLTZL
    assign branch2D = ( (~|(instr2D[31:26] ^ `REGIMM_INST)) & (~|(instr2D[19:17] ^ 3'b000) | (~|(instr2D[19:17] ^ 3'b001))) ) 
                    | (~|(instr2D[31:26][5:2] ^ 4'b0001)); 

    parameter Strongly_not_taken = 2'b00, Weakly_not_taken = 2'b01, Weakly_taken = 2'b11, Strongly_taken = 2'b10;
    parameter PHT_DEPTH = 6;
    parameter BHT_DEPTH = 10;

    reg [5:0] BHT [(1<<BHT_DEPTH)-1 : 0];
    reg [1:0] PHT [(1<<PHT_DEPTH)-1:0];
    
    wire [(PHT_DEPTH-1):0] PHT1_index;
    wire [(BHT_DEPTH-1):0] BHT1_index;
    wire [(PHT_DEPTH-1):0] BHR1_value;

    assign BHT1_index = PcF2[11:2];     
    assign BHR1_value = BHT[BHT1_index];  
    assign PHT1_index = BHR1_value;

    assign pred_take1F2 = PHT[PHT1_index][1];

    wire [(PHT_DEPTH-1):0] PHT2_index;
    wire [(BHT_DEPTH-1):0] BHT2_index;
    wire [(PHT_DEPTH-1):0] BHR2_value;

    assign BHT2_index = PcPlus4F2[11:2];     
    assign BHR2_value = BHT[BHT2_index];  
    assign PHT2_index = BHR2_value;

    assign pred_take2F2 = PHT[PHT2_index][1];

// ---------------------------------------BHT初始化以及更新---------------------------------------
    wire [(PHT_DEPTH-1):0] update_PHT1_index;
    wire [(BHT_DEPTH-1):0] update_BHT1_index;
    wire [(PHT_DEPTH-1):0] update_BHR1_value;
    assign update_BHT1_index = pcE[11:2];     
    assign update_BHR1_value = BHT[update_BHT1_index];  
    assign update_PHT1_index = update_BHR1_value;

    wire [(PHT_DEPTH-1):0] update_PHT2_index;
    wire [(BHT_DEPTH-1):0] update_BHT2_index;
    wire [(PHT_DEPTH-1):0] update_BHR2_value;
    assign update_BHT2_index = PcPlus4E[11:2];     
    assign update_BHR2_value = BHT[update_BHT2_index];  
    assign update_PHT2_index = update_BHR2_value;

    always@(posedge clk) begin
        if(rst) begin
            BHT <= '{default:'0};
        end
        else if(branch1E) begin
            BHT[update_BHT1_index] <= {BHT[update_BHT1_index] << 1, actual_take1E};
        end
        else if(branch2E) begin
            BHT[update_BHT2_index] <= {BHT[update_BHT2_index] << 1, actual_take1E};
        end
    end
// ---------------------------------------BHT初始化以及更新---------------------------------------

// ---------------------------------------PHT初始化以及更新---------------------------------------
    always @(posedge clk) begin
        if(rst) begin
            PHT = '{default:'0};
        end
        else begin
            case(PHT[update_PHT1_index])
                Strongly_not_taken  :   PHT[update_PHT1_index] <= actual_take1E ? Weakly_not_taken : Strongly_not_taken;
                Weakly_not_taken    :   PHT[update_PHT1_index] <= actual_take1E ? Weakly_taken : Strongly_not_taken;
                Weakly_taken        :   PHT[update_PHT1_index] <= actual_take1E ? Strongly_taken : Weakly_not_taken;
                Strongly_taken      :   PHT[update_PHT1_index] <= actual_take1E ? Strongly_taken : Weakly_taken;
            endcase 
            case(PHT[update_PHT2_index])
                Strongly_not_taken  :   PHT[update_PHT2_index] <= actual_take2E ? Weakly_not_taken : Strongly_not_taken;
                Weakly_not_taken    :   PHT[update_PHT2_index] <= actual_take2E ? Weakly_taken : Strongly_not_taken;
                Weakly_taken        :   PHT[update_PHT2_index] <= actual_take2E ? Strongly_taken : Weakly_not_taken;
                Strongly_taken      :   PHT[update_PHT2_index] <= actual_take2E ? Strongly_taken : Weakly_taken;
            endcase 
        end
    end
// ---------------------------------------PHT初始化以及更新---------------------------------------

// --------------------------pipeline------------------------------
    always @(posedge clk) begin
        if(rst | flush_masterD) begin
            pred_take1D_r <= 0;
        end
        else if(~stall_masterD) begin
            pred_take1D_r <= pred_take1F2;
        end
    end
    always @(posedge clk) begin
        if(rst | flush_slaveD) begin
            pred_take2D_r <= 0;
        end
        else if(~stall_slaveD) begin
            pred_take2D_r <= pred_take2F2;
        end
    end
// --------------------------pipeline------------------------------

    assign pred_take1D = branch1D & pred_take1D_r;    // 为branch指令且预测跳转
    assign pred_take2D = branch2D & pred_take2D_r;    // 为branch指令且预测跳转

endmodule