`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/07 10:58:03
// Design Name: 
// Module Name: mips
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mips(
	input wire clk,rst,
	input wire  [5 :0] ext_int, //异常处理
    
    //inst
    output wire [31:0] inst_addrF,  //指令地址
    output wire        inst_enF,  //使能
    input wire  [31:0] instrF,  //注：instr ram时钟取反

    //data
    output wire mem_enM,                    
    output wire [31:0] mem_addrM,     //�?/写地�?
    input  wire [31:0] mem_rdataM,    //读数�?
    output wire [3 :0] mem_wenM,      //选择写哪�?�?
    output wire [31:0] writedataM,   //写数�?
	// input wire         d_cache_stall,
	//debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
    );
	wire [31:0] virtual_mem_addr;
    wire [31:0] virtual_instr_addr;

    mmu mmu(.inst_vaddr(virtual_instr_addr),.inst_paddr(inst_addrF),
            .data_vaddr(virtual_mem_addr),.data_paddr(mem_addrM));
            
	datapath dp(
		.clk(clk),.rst(rst),
		.ext_int(ext_int),
    	.inst_addrF(virtual_instr_addr), .inst_enF(inst_enF),.instrF(instrF),

    	.mem_enM(mem_enM),.mem_addrM(virtual_mem_addr),.mem_rdataM(mem_rdataM),
        .mem_wenM(mem_wenM),.writedataM(writedataM),.d_cache_stall(0),
		//debug interface
		.debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_wen(debug_wb_rf_wen),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
	    );
	
endmodule
