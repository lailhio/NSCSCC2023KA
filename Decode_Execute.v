`timescale 1ns / 1ps


module Decode_Execute (
	input wire clk,rst,flushE,
	input wire[31:0] srcaD,
    input wire[31:0] srcbD,
    input wire [31:0]signimmD,
    input wire [4:0]rsD,
    input wire [4:0]rtD,
    input wire [4:0]rdD,
    input wire [4:0]saD,
    input wire memtoregD,memwriteD,alusrcD,regdstD,regwriteD,
    input wire [4:0]alucontrolD,
    input wire [2:0] fcD,
	output reg[31:0] srcaE,
    output reg[31:0] srcbE,
    output reg [31:0]signimmE,
    output reg [4:0]rsE,
    output reg [4:0]rtE,
    output reg [4:0]rdE,
    output reg [4:0]saE,
    output reg memtoregE,memwriteE,alusrcE,regdstE,regwriteE,
    output reg [4:0]alucontrolE,
    output reg [2:0] fcE
    );
    always @(posedge clk) begin
        if(rst | flushE) begin
			srcaE<=0;
            srcbE<=0;
            signimmE<=0;
            rsE<=0;
            rtE<=0;
            rdE<=0;
            saE<=0;
            memtoregE<=0;
            memwriteE<=0;
            alusrcE<=0;
            regdstE<=0;
            regwriteE<=0;
            alucontrolE<=0;
            fcE<=0;
		end
        else  begin
            srcaE<=srcaD;
            srcbE<=srcbD;
            signimmE<=signimmD;
            rsE<=rsD;
            rtE<=rtD;
            rdE<=rdD;
            saE<=saD;
            memtoregE<=memtoregD;
            memwriteE<=memwriteD;
            alusrcE<=alusrcD;
            regdstE<=regdstD;
            regwriteE<=regwriteD;
            alucontrolE<=alucontrolD;
            fcE<=fcD;
        end
	end
endmodule