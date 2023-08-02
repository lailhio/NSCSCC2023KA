`timescale 1ns / 1ps

module tlb_trans (
    input wire clk, rst,
    input wire stall_masterM, flush_masterM, stallF,
    input wire [31:0] inst_vaddr,
    input wire [31:0] data_vaddr,
    input wire inst_en,
    input wire mem_read_enM, mem_write_enM,

    output wire [`TAG_WIDTH-1:0] inst_pfn,
    output wire [`TAG_WIDTH-1:0] data_pfn,
    output wire no_cache_i,
    output wire no_cache_d,
    
    //异常
    output wire inst_tlb_refill, inst_tlb_invalid,
    output wire data_tlb_refill, data_tlb_invalid, data_tlb_modify,

    //TLB指令
	input  wire        TLBP,
	input  wire        TLBR,
    input  wire        TLBWI,
    input  wire        TLBWR,
    
    input  wire [31:0] EntryHi_in,
	input  wire [31:0] PageMask_in,
	input  wire [31:0] EntryLo0_in,
	input  wire [31:0] EntryLo1_in,
	input  wire [31:0] Index_in,
    input  wire [31:0] Random_in,

	output wire [31:0] EntryHi_out,
	output wire [31:0] PageMask_out,
	output wire [31:0] EntryLo0_out,
	output wire [31:0] EntryLo1_out,
	output wire [31:0] Index_out
);
endmodule