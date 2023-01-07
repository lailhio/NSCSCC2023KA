`timescale 1ns / 1ps
module Mem_WriteBack (
    input wire clk, rst,
    input wire stallW,
    input wire flushW,
    input wire [31:0] pcM,
    input wire [31:0] aluoutM,
    input wire [4:0] writeregM,
    input wire regwriteM,
    input wire [31:0] mem_rdataM,
    input wire [31:0] resultM,
    input wire flush_exceptionM,


    output reg [31:0] pcW,
    output reg [31:0] aluoutW,
    output reg [4:0] writeregW,
    output reg regwriteW,
    output reg [31:0] mem_rdataW,
    output reg [31:0] resultW,
    output reg flush_exceptionW
);
    always @(posedge clk) begin
        if(rst) begin
            pcW <= 0;
            aluoutW <= 0;
            writeregW <= 0;
            regwriteW <= 0;
            mem_rdataW <= 0;
            resultW <= 0;
            flush_exceptionW<=0;
        end
        else if(flushW)begin
            pcW <= 0;
            aluoutW <= 0;
            writeregW <= 0;
            regwriteW <= 0;
            mem_rdataW <= 0;
            resultW <= 0;
            flush_exceptionW<=flush_exceptionM;
        end
        else if(~stallW) begin
            pcW <= pcM;
            aluoutW <= aluoutM;
            writeregW <= writeregM;
            regwriteW <= regwriteM;
            mem_rdataW <= mem_rdataM;
            resultW <= resultM;
            flush_exceptionW<=flush_exceptionM;
        end
    end
endmodule