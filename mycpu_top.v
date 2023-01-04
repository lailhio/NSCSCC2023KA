module mycpu_top(
    input clk,
    input resetn,  //low active
    input  wire [5 :0] ext_int,

    //cpu inst sram
    output        inst_sram_en   ,
    output [3 :0] inst_sram_wen  ,
    output [31:0] inst_sram_addr ,
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,
    //cpu data sram
    output        data_sram_en   ,
    output [3 :0] data_sram_wen  ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    //debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
);

    mips mips(
        .clk(clk),
        .rst(~resetn),
        .ext_int(ext_int),
        .inst_addrF(inst_sram_addr), .inst_enF(inst_sram_en),.instrF(inst_sram_rdata),

        .mem_enM(data_sram_en),.mem_addrM(data_sram_addr),.mem_rdataM(data_sram_rdata),
        .mem_wenM(data_sram_wen),.writedataM(data_sram_wdata),
        .debug_wb_pc(debug_wb_pc),
        .debug_wb_rf_wen(debug_wb_rf_wen),
        .debug_wb_rf_wnum(debug_wb_rf_wnum),
        .debug_wb_rf_wdata(debug_wb_rf_wdata)
    );

    //ascii
    //use for debug
    // 指令转化为ascii�?
    wire [39:0] ascii;
    instdec instdec(
        .instr(inst_sram_rdata),
        .ascii(ascii)
    );

endmodule