`timescale 1ns / 1ps
module Mem_WriteBack (
    input wire clk, rst,
    input wire stallW,
    input wire [31:0] pcM,
    input wire [31:0] aluoutM,
    input wire [4:0] writeregM,
    input wire writeregM,
    input wire [31:0] mem_rdataM,
    input wire [31:0] resultM,


    output reg [31:0] pcW,
    output reg [31:0] aluoutW,
    output reg [4:0] writeregW,
    output reg writeregW,
    output reg [31:0] mem_rdataW,
    output reg [31:0] resultW
);
    always @(posedge clk) begin
        if(rst) begin
            pcW <= 0;
            aluoutW <= 0;
            writeregW <= 0;
            writeregW <= 0;
            mem_rdataW <= 0;
            resultW <= 0;
        end
        else if(~stallW) begin
            pcW <= pcM;
            aluoutW <= aluoutM;
            writeregW <= writeregM;
            writeregW <= writeregM;
            mem_rdataW <= mem_rdataM;
            resultW <= resultM;
        end
    end
endmodule