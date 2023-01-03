`timescale 1ns / 1ps


module Fetch_Decode (
	input wire clk,rst,stallD,flushD
	input wire[31:0] pcplus4F,
    input wire[31:0] instrF,
	output reg[31:0] pcplus4D,
    output reg[31:0] instrD,
    );
    always @(posedge clk) begin
        if(rst | flushD) begin
			pcplus4D<=0;
            instrD<=0;
		end
        else if(~stallD) begin
            pcplus4D<=pcplus4F;
            instrD<=instrF;
        end
	end
endmodule