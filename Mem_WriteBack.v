`timescale 1ns / 1ps
module Mem_WriteBack (
	input wire clk,rst,
	input wire[31:0] aluoutM,
    input wire[31:0] readdataM,
    input wire [4:0]writeregM,
    input wire memtoregM,regwriteM,
    input wire [2:0] fcM,
	output reg[31:0] aluoutW,
    output reg[31:0] readdataW,
    output reg [4:0]writeregW,
    output reg memtoregW,regwriteW,
    output reg [2:0] fcW
    );
    always @(posedge clk) begin
        if(rst) begin
			aluoutW<=0;
            readdataW<=0;
            writeregW<=0;
            memtoregW<=0;
            regwriteW<=0;
            fcW<=0;
		end
        else  begin
            aluoutW<=aluoutM;
            readdataW<=readdataM;
            writeregW<=writeregM;
            memtoregW<=memtoregM;
            regwriteW<=regwriteM;
            fcW<=fcM;
        end
	end
endmodule