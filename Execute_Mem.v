`timescale 1ns / 1ps
module Execute_Mem (
	input wire clk,rst,
	input wire[31:0] srcb2E,
    input wire [31:0]aluoutE,
    input wire [4:0]writeregE,
    input wire memtoregE,memwriteE,regwriteE,
    input wire [2:0] fcE,

	output reg[31:0] writedataM2,
    output reg [31:0]aluoutM,
    output reg [4:0]writeregM,
    output reg memtoregM,memwriteM,regwriteM,
    output reg [2:0] fcM
    );
    always @(posedge clk) begin
        if(rst) begin
			writedataM2<=0;
            aluoutM<=0;
            writeregM<=0;
            memtoregM<=0;
            memwriteM<=0;
            regwriteM<=0;
            fcM<=0;
		end
        else  begin
            writedataM2<=srcb2E;
            aluoutM<=aluoutE;
            writeregM<=writeregE;
            memtoregM<=memtoregE;
            memwriteM<=memwriteE;
            regwriteM<=regwriteE;
            fcM<=fcE;
        end
	end

endmodule