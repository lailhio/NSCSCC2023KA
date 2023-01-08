`timescale 1ns / 1ps



module mips(
	input wire clk,rst,
	input wire  [5 :0] ext_int, //异常处理
    //instr
    output wire inst_req,
    output wire inst_wr,
    output wire [1:0] inst_size,
    output wire [31:0] physics_inst_addr,
    output wire [31:0] inst_wdata,
    input wire inst_addr_ok,
    input wire inst_data_ok,
    input wire [31:0] inst_rdata,

    //data
    output wire data_req,
    output wire data_wr,
    output wire [1:0] data_size,
    output wire [31:0] physics_data_addr,
    output wire [31:0] data_wdata,
    input wire data_addr_ok,
    input wire data_data_ok,
    input wire [31:0] data_rdata,

    output wire no_dcache,

	//debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
    );
    //从datapath得到的虚拟地址
	wire [31:0] virtual_data_addr;
    wire [31:0] virtual_instr_addr;
    //datapath传出来的sram信号
    wire inst_sram_en           ;
    wire [31:0] inst_sram_rdata ;
    wire i_stall;

    wire data_sram_en           ;
    wire [31:0] data_sram_rdata ;
    wire [3:0] data_sram_wen    ;
    wire [31:0] data_sram_wdata ;
    wire d_stall;

    
            
	datapath dp(
		.clk(clk),.rst(rst),
		.ext_int(ext_int),
        //instruction
    	.inst_addrF(virtual_instr_addr), .inst_enF(inst_sram_en),
        .instrF(inst_sram_rdata),
        .i_cache_stall(i_stall),
        //data
    	.mem_addrM(virtual_data_addr),.mem_enM(data_sram_en),
        .mem_rdataM(data_sram_rdata),
        .mem_wenM(data_sram_wen),.writedataM(data_sram_wdata),
        .d_cache_stall(d_stall),
        
        .longest_stall(longest_stall),
		//debug interface
		.debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_wen(debug_wb_rf_wen),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
	    );

    //inst sram to sram-like
    i_sram_to_sram_like i_sram_to_sram_like(
        .clk(clk), .rst(rst),
        //sram
        .inst_sram_en(inst_sram_en),
        .inst_sram_addr(virtual_instr_addr),
        .inst_sram_rdata(inst_sram_rdata),
        .i_stall(i_stall),
        //sram like
        .inst_req(inst_req), 
        .inst_wr(inst_wr),
        .inst_size(inst_size),
        .inst_addr(inst_addr),   
        .inst_wdata(inst_wdata),
        .inst_addr_ok(inst_addr_ok),
        .inst_data_ok(inst_data_ok),
        .inst_rdata(inst_rdata),

        .longest_stall(longest_stall)
    );

    //data sram to sram-like
    d_sram_to_sram_like d_sram_to_sram_like(
        .clk(clk), .rst(rst),
        //sram
        .data_sram_en(data_sram_en),
        .data_sram_addr(virtual_data_addr),
        .data_sram_rdata(data_sram_rdata),
        .data_sram_wen(data_sram_wen),
        .data_sram_wdata(data_sram_wdata),
        .d_stall(d_stall),
        //sram like
        .data_req(data_req),    
        .data_wr(data_wr),
        .data_size(data_size),
        .data_addr(data_addr),   
        .data_wdata(data_wdata),
        .data_addr_ok(data_addr_ok),
        .data_data_ok(data_data_ok),
        .data_rdata(data_rdata),

        .longest_stall(longest_stall)
    );

	mmu mmu(.inst_vaddr(virtual_instr_addr),.inst_paddr(physics_inst_addr),
            .data_vaddr(virtual_data_addr),.data_paddr(physics_data_addr),
            .no_dcache(no_dcache));
endmodule
