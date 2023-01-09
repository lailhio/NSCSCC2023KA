`timescale 1ns / 1ps


module Decode_Execute (
    input wire clk, rst,stallE,flushE,
    input wire [31:0] pcD,
    input wire [31:0] rd1D, rd2D,
    input wire [4:0] rsD, rtD, rdD,
    input wire [31:0] immD,
    input wire [31:0] pc_plus4D,
    input wire [31:0] instrD,
    input wire [31:0] pc_branchD,
    input wire pred_takeD,
    input wire branchD,
    input wire jump_conflictD,
    input wire [4:0] saD,
    input wire is_in_delayslot_iD,
    input wire [4:0] alucontrolD,
    input wire jumpD,
    input wire [4:0] branch_judge_controlD,
    input wire [1:0]  regdstD,
    input wire is_immD,regwriteD,
    input wire mem_readD, mem_writeD,
    input wire memtoregD,         	//result选择 0->aluout, 1->read_data
    input wire hilo_to_regD,			// 00--aluoutM; 01--hilo_o; 10 11--rdataM;
    input wire riD,
    input wire breakD, syscallD, eretD, 
    input wire cp0_wenD,
    input wire cp0_to_regD,
    input wire is_mfcD,   //为mfc0

    output reg [31:0] pcE,
    output reg [31:0] rd1E, rd2E,
    output reg [4:0] rsE, rtE, rdE,
    output reg [31:0] immE,
    output reg [31:0] pc_plus4E,
    output reg [31:0] instrE,
    output reg [31:0] pc_branchE,
    output reg pred_takeE,
    output reg branchE,
    output reg jump_conflictE,    
    output reg [4:0] saE,        
    output reg is_in_delayslot_iE,
    output reg [4:0] alucontrolE,
    output reg jumpE,
    output reg [4:0] branch_judge_controlE,
    output reg [1:0]  regdstE,
    output reg is_immE,regwriteE,
    output reg mem_readE, mem_writeE,
    output reg memtoregE,         	//result选择 0->aluout, 1->read_data
    output reg hilo_to_regE,			// 00--aluoutM; 01--hilo_o; 10 11--rdataM;
    output reg riE,
    output reg breakE, syscallE, eretE, 
    output reg cp0_wenE,
    output reg cp0_to_regE,
    output reg is_mfcE   //为mfc0
);
    always @(posedge clk) begin
        if(rst | flushE) begin
            pcE                     <=   0 ;
            rd1E                    <=   0 ;
            rd2E                    <=   0 ;
            rsE                     <=   0 ;
            rtE                     <=   0 ;
            rdE                     <=   0 ;
            immE                    <=   0 ;
            pc_plus4E               <=   0 ;
            instrE                  <=   0 ;
            pc_branchE              <=   0 ;
            pred_takeE              <=   0 ;
            branchE                 <=   0 ;
            jump_conflictE          <=   0 ;
            saE                     <=   0 ;
            is_in_delayslot_iE      <=   0 ;
            alucontrolE             <=   0 ;
            jumpE                   <=   0 ;
            branch_judge_controlE   <=   0 ;
            regdstE                 <=   0 ;
            is_immE                 <=   0 ;
            regwriteE               <=   0 ;
            mem_readE               <=   0 ;
            mem_writeE              <=   0 ;
            memtoregE               <=   0 ;
            hilo_to_regE            <=   0 ;
            riE                     <=   0 ;
            breakE                  <=   0 ;
            syscallE                <=   0 ;
            eretE                   <=   0 ;
            cp0_wenE                <=   0 ;
            cp0_to_regE             <=   0 ;
            is_mfcE                 <=   0 ;
        end 
        else if(~stallE) begin
            pcE                     <= pcD                  ;
            rd1E                    <= rd1D                 ;
            rd2E                    <= rd2D                 ;
            rsE                     <= rsD                  ;
            rtE                     <= rtD                  ;
            rdE                     <= rdD                  ;
            immE                    <= immD                 ;
            pc_plus4E               <= pc_plus4D            ;
            instrE                  <= instrD               ;
            pc_branchE              <= pc_branchD           ;
            pred_takeE              <= pred_takeD           ;
            branchE                 <= branchD              ;
            jump_conflictE          <= jump_conflictD       ;
            saE                     <= saD                  ;
            is_in_delayslot_iE      <= is_in_delayslot_iD   ;
            alucontrolE            <= alucontrolD         ;
            jumpE                   <= jumpD                ;
            branch_judge_controlE   <= branch_judge_controlD;
            regdstE                 <=   regdstD ;
            is_immE                 <=  is_immD ;
            regwriteE                <=  regwriteD ;
            mem_readE               <=   mem_readD ;
            mem_writeE              <=   mem_writeD ;
            memtoregE               <=   memtoregD ;
            hilo_to_regE            <=  hilo_to_regD ;
            riE                     <=  riD ;
            breakE                  <=  breakD;
            syscallE                <=  syscallD ;
            eretE                   <=  eretD;
            cp0_wenE                <=   cp0_wenD;
            cp0_to_regE             <=  cp0_to_regD;
            is_mfcE                 <=   is_mfcD;
        end
    end
endmodule