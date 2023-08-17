`timescale 1ns / 1ps
module mmu (
    input wire  [31:0] inst_vaddr,
    output wire [31:0] inst_paddr,
    input wire  [31:0] data_vaddr,
    output wire [31:0] data_paddr,
    input wire         data_sram_en,
    input wire [3:0]   data_sram_wen,
    output wire        data_wr,
    output wire no_dcache, no_icache    //是否经过d cache
);
    wire inst_kseg0, inst_kseg1;
    wire data_kseg0, data_kseg1;

    
    assign data_wr = data_sram_en & |data_sram_wen;
    
    
    assign inst_kseg0 = inst_vaddr[31:29] == 3'b100;
    assign inst_kseg1 = inst_vaddr[31:29] == 3'b101;
    assign data_kseg0 = data_vaddr[31:29] == 3'b100;
    assign data_kseg1 = data_vaddr[31:29] == 3'b101;

    assign inst_paddr = inst_kseg0 | inst_kseg1 ?
           {3'b0, inst_vaddr[28:0]} : inst_vaddr;
    assign data_paddr = data_kseg0 | data_kseg1 ?
           {3'b0, data_vaddr[28:0]} : data_vaddr;
    
    assign no_dcache = data_kseg1 ? 1'b1 : 1'b0;
    assign no_icache = inst_kseg1 ? 1'b1 : 1'b0;

endmodule