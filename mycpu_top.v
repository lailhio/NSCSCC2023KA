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
    wire        cpu_inst_req  ;
    wire [31:0] cpu_inst_addr ;
    wire        cpu_inst_wr   ;
    wire [1:0]  cpu_inst_size ;
    wire [31:0] cpu_inst_wdata;
    wire [31:0] cpu_inst_rdata;
    wire        cpu_inst_addr_ok;
    wire        cpu_inst_data_ok;

    wire        cpu_data_req  ;
    wire [31:0] cpu_data_addr ;
    wire        cpu_data_wr   ;
    wire [1:0]  cpu_data_size ;
    wire [31:0] cpu_data_wdata;
    wire [31:0] cpu_data_rdata;
    wire        cpu_data_addr_ok;
    wire        cpu_data_data_ok;
    mips mips(
    .clk(~clk), .rst(~resetn),
    .ext_int(ext_int),

    .inst_req     (cpu_inst_req  ),     .inst_wr      (cpu_inst_wr   ),
    .inst_addr    (cpu_inst_addr ),     .inst_size    (cpu_inst_size ),
    .inst_wdata   (cpu_inst_wdata),     .inst_rdata   (cpu_inst_rdata),
    .inst_addr_ok (cpu_inst_addr_ok),   .inst_data_ok (cpu_inst_data_ok),

    .data_req     (cpu_data_req  ),     .data_wr      (cpu_data_wr   ),
    .data_addr    (cpu_data_addr ),     .data_wdata   (cpu_data_wdata),
    .data_size    (cpu_data_size ),     .data_rdata   (cpu_data_rdata),
    .data_addr_ok (cpu_data_addr_ok),   .data_data_ok (cpu_data_data_ok),

    .debug_wb_pc       (debug_wb_pc       ),
    .debug_wb_rf_wen   (debug_wb_rf_wen   ),
    .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
    .debug_wb_rf_wdata (debug_wb_rf_wdata )
);






    //ascii
    //use for debug
    instdec instdec(
        .instr(inst_sram_rdata)
    );

endmodule