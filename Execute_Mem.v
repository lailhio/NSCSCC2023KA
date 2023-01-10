`timescale 1ns / 1ps
module Execute_Mem (
    input wire clk, rst,flushM,
    input wire stallM,
    input wire [31:0] pcE,
    input wire [63:0] aluoutE,
    input wire [31:0] rt_valueE,
    input wire [4:0] writeregE,
    input wire regwriteE,
    input wire [31:0] instrE,
    input wire branchE,
    input wire pred_takeE,
    input wire [31:0] pc_branchE,
    input wire overflowE,
    input wire is_in_delayslot_iE,
    input wire [4:0] rdE,
    input wire actual_takeE,
    input wire mem_readE, mem_writeE,
    input wire memtoregE,         	//result选择 0->aluout, 1->read_data
    input wire hilotoregE,			// 00--aluoutM; 01--hilo_o; 10 11--rdataM;
    input wire riE,
    input wire breakE, syscallE, eretE, 
    input wire cp0_wenE,
    input wire cp0_to_regE,
    input wire is_mfcE,   //为mfc0

    output reg [31:0] pcM,
    output reg [31:0] aluoutM,
    output reg [31:0] rt_valueM,
    output reg [4:0] writeregM,
    output reg regwriteM,
    output reg [31:0] instrM,
    output reg branchM,
    output reg pred_takeM,
    output reg [31:0] pc_branchM,
    output reg overflowM,        
    output reg is_in_delayslot_iM,
    output reg [4:0] rdM,
    output reg actual_takeM,
    output reg mem_readM, mem_writeM,
    output reg memtoregM,         	//result选择 0->aluout, 1->read_data
    output reg hilotoregM,			// 00--aluoutM; 01--hilo_o; 10 11--rdataM;
    output reg riM,
    output reg breakM, syscallM, eretM, 
    output reg cp0_wenM,
    output reg cp0_to_regM,
    output reg is_mfcM   //为mfc0
);
    always @(posedge clk) begin
        if(rst | flushM) begin
            pcM                     <=              0;
            aluoutM                <=              0;
            rt_valueM               <=              0;
            writeregM              <=              0;
            regwriteM              <=              0;
            instrM                  <=              0;
            branchM                 <=              0;
            pred_takeM              <=              0;
            pc_branchM              <=              0;
            overflowM               <=              0;
            is_in_delayslot_iM      <=              0;
            rdM                     <=              0;
            actual_takeM            <=              0;
            mem_readM               <=              0;
            mem_writeM             <=              0;
            memtoregM               <=              0;
            hilotoregM           <=              0;     
            riM                     <=              0;
            breakM                  <=              0;
            syscallM                <=              0;  
            eretM                   <=              0;
            cp0_wenM                <=              0;
            cp0_to_regM             <=              0;
            is_mfcM                 <=              0;
        end
        else if(~stallM) begin
            pcM                     <=           pcE                ;
            aluoutM                <=           aluoutE[31:0]     ;
            rt_valueM               <=           rt_valueE          ;
            writeregM              <=           writeregE         ;
            regwriteM              <=           regwriteE          ;
            instrM                  <=           instrE             ;
            branchM                 <=           branchE            ;
            pred_takeM              <=           pred_takeE         ;
            pc_branchM              <=           pc_branchE         ;
            overflowM               <=           overflowE          ;
            is_in_delayslot_iM      <=           is_in_delayslot_iE ;
            rdM                     <=           rdE                ;
            actual_takeM            <=           actual_takeE       ;
            mem_readM               <=             mem_readE        ;
            mem_writeM             <=              mem_writeE       ;
            memtoregM               <=              memtoregE       ;
            hilotoregM           <=              hilotoregE     ;     
            riM                     <=              riE             ;
            breakM                  <=              breakE          ;
            syscallM                <=              syscallE        ;  
            eretM                   <=              eretE           ;
            cp0_wenM                <=              cp0_wenE        ;
            cp0_to_regM             <=              cp0_to_regE     ;
            is_mfcM                 <=              is_mfcE         ;
        end
    end
endmodule