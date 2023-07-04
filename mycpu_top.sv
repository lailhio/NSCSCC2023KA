module mycpu_top(
    input [5:0] ext_int,   //high active  //input

    input wire aclk,    
    input wire aresetn,   //low active

    output wire[3:0] arid,
    output wire[31:0] araddr,
    output wire[7:0] arlen,
    output wire[2:0] arsize,
    output wire[1:0] arburst,
    output wire[1:0] arlock,
    output wire[3:0] arcache,
    output wire[2:0] arprot,
    output wire arvalid,
    input wire arready,
  
    input wire[3:0] rid,
    input wire[31:0] rdata,
    input wire[1:0] rresp,
    input wire rlast,
    input wire rvalid,
    output wire rready, 
 
    output wire[3:0] awid,
    output wire[31:0] awaddr,
    output wire[7:0] awlen,
    output wire[2:0] awsize,
    output wire[1:0] awburst,
    output wire[1:0] awlock,
    output wire[3:0] awcache,
    output wire[2:0] awprot,
    output wire awvalid,
    input wire awready,
    
    output wire[3:0] wid,
    output wire[31:0] wdata,
    output wire[3:0] wstrb,
    output wire wlast,
    output wire wvalid,
    input wire wready,
    
    input wire[3:0] bid,
    input wire[1:0] bresp,
    input bvalid,
    output bready,

    //debug interface
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
);
    wire rst,clk;
    wire no_dcache;
    assign clk=aclk;
    assign rst=~aresetn;

    wire cpu_inst_req  ;
    wire [31:0] cpu_inst_addr ;
    wire cpu_inst_wr   ;
    wire [1:0]  cpu_inst_size ;
    wire [31:0] cpu_inst_wdata;
    wire [31:0] cpu_inst_rdata;
    wire cpu_inst_addr_ok;
    wire cpu_inst_data_ok;

    wire cpu_data_req  ;
    wire [31:0] cpu_data_addr ;
    wire cpu_data_wr   ;
    wire [1:0]  cpu_data_size ;
    wire [31:0] cpu_data_wdata;
    wire [31:0] cpu_data_rdata;
    wire cpu_data_addr_ok;
    wire cpu_data_data_ok;

    wire cache_inst_req  ;
    wire [31:0] cache_inst_addr ;
    wire cache_inst_wr   ;
    wire [1:0]  cache_inst_size ;
    wire [31:0] cache_inst_wdata;
    wire [31:0] cache_inst_rdata;
    wire cache_inst_addr_ok;
    wire cache_inst_data_ok;

    wire cache_data_req  ;
    wire [31:0] cache_data_addr ;
    wire cache_data_wr   ;
    wire [1:0]  cache_data_size ;
    wire [31:0] cache_data_wdata;
    wire [31:0] cache_data_rdata;
    wire cache_data_addr_ok;
    wire cache_data_data_ok;

    wire fast_data_req  ;
    wire [31:0] fast_data_addr ;
    wire fast_data_wr   ;
    wire [1:0]  fast_data_size ;
    wire [31:0] fast_data_wdata;
    wire [31:0] fast_data_rdata;
    wire fast_data_addr_ok;
    wire fast_data_data_ok;

    wire conf_data_req  ;
    wire [31:0] conf_data_addr ;
    wire conf_data_wr   ;
    wire [1:0]  conf_data_size ;
    wire [31:0] conf_data_wdata;
    wire [31:0] conf_data_rdata;
    wire conf_data_addr_ok;
    wire conf_data_data_ok;

    wire wrap_data_req  ;
    wire [31:0] wrap_data_addr ;
    wire wrap_data_wr   ;
    wire [1:0]  wrap_data_size ;
    wire [31:0] wrap_data_wdata;
    wire [31:0] wrap_data_rdata;
    wire wrap_data_addr_ok;
    wire wrap_data_data_ok;


mips mips(
    .clk(clk), .rst(rst),
    .ext_int(ext_int),
    //mips传出的inst请求
    .inst_req     (cpu_inst_req  ),     .inst_wr      (cpu_inst_wr   ),
    .physics_inst_addr    (cpu_inst_addr ),     .inst_size    (cpu_inst_size ),
    .inst_wdata   (cpu_inst_wdata),     
    //mips得到的inst回复
    .inst_rdata   (cpu_inst_rdata),
    .inst_addr_ok (cpu_inst_addr_ok),   .inst_data_ok (cpu_inst_data_ok),

    //mips传出的data请求
    .data_req     (cpu_data_req  ),     .data_wr      (cpu_data_wr   ),
    .physics_data_addr    (cpu_data_addr ),     .data_wdata   (cpu_data_wdata),
    .data_size    (cpu_data_size ), 
    //mips得到的data回复
    .data_rdata   (cpu_data_rdata),
    .data_addr_ok (cpu_data_addr_ok),   .data_data_ok (cpu_data_data_ok),

    .no_dcache(no_dcache),

    .debug_wb_pc(debug_wb_pc),
    .debug_wb_rf_wen   (debug_wb_rf_wen   ),
    .debug_wb_rf_wnum  (debug_wb_rf_wnum  ),
    .debug_wb_rf_wdata (debug_wb_rf_wdata )
);
bridge_1x2 bridge_1x2 (
    .no_dcache(no_dcache),
    //mips传出的data请求
    .cpu_data_req     (cpu_data_req  ),     .cpu_data_wr      (cpu_data_wr   ),
    .cpu_data_addr    (cpu_data_addr ),     .cpu_data_wdata   (cpu_data_wdata),
    .cpu_data_size    (cpu_data_size ), 
    //传向mips的data回复
    .cpu_data_rdata   (cpu_data_rdata),
    .cpu_data_addr_ok (cpu_data_addr_ok),   .cpu_data_data_ok (cpu_data_data_ok),

    //应当前往cache的data请求
    .fast_data_req     (fast_data_req  ),     .fast_data_wr      (fast_data_wr   ),
    .fast_data_addr    (fast_data_addr ),     .fast_data_wdata   (fast_data_wdata),
    .fast_data_size    (fast_data_size ), 
    //从cache得到的data回复
    .fast_data_rdata   (fast_data_rdata),
    .fast_data_addr_ok (fast_data_addr_ok),   .fast_data_data_ok (fast_data_data_ok),

    //不过cache的data请求
    .conf_data_req     (conf_data_req  ),     .conf_data_wr      (conf_data_wr   ),
    .conf_data_addr    (conf_data_addr ),     .conf_data_wdata   (conf_data_wdata),
    .conf_data_size    (conf_data_size ), 
    //不过cache得到的data回复
    .conf_data_rdata   (conf_data_rdata),
    .conf_data_addr_ok (conf_data_addr_ok),   .conf_data_data_ok (conf_data_data_ok)
);

d_cache d_cache (
    .clk(clk), .rst(rst),

    .cpu_data_req(fast_data_req),    .cpu_data_wr(fast_data_wr),
    .cpu_data_size(fast_data_size),  .cpu_data_addr(fast_data_addr),
    .cpu_data_wdata(fast_data_wdata), 

    .cpu_data_rdata(fast_data_rdata),
    .cpu_data_addr_ok(fast_data_addr_ok) ,.cpu_data_data_ok(fast_data_data_ok) ,

    .cache_data_req(cache_data_req),    .cache_data_wr(cache_data_wr),
    .cache_data_size(cache_data_size),  .cache_data_addr(cache_data_addr),
    .cache_data_wdata(cache_data_wdata), 

    .cache_data_rdata(cache_data_rdata),
    .cache_data_addr_ok(cache_data_addr_ok) ,.cache_data_data_ok(cache_data_data_ok)
);

i_cache i_cache(
    .clk(clk), .rst(rst),
    
    .cpu_inst_req(cpu_inst_req),    .cpu_inst_wr(cpu_inst_wr),
    .cpu_inst_size(cpu_inst_size),  .cpu_inst_addr(cpu_inst_addr),
    .cpu_inst_wdata(cpu_inst_wdata), 

    .cpu_inst_rdata(cpu_inst_rdata),
    .cpu_inst_addr_ok(cpu_inst_addr_ok) ,.cpu_inst_data_ok(cpu_inst_data_ok) ,

    .cache_inst_req(cache_inst_req),    .cache_inst_wr(cache_inst_wr),
    .cache_inst_size(cache_inst_size),  .cache_inst_addr(cache_inst_addr),
    .cache_inst_wdata(cache_inst_wdata), 

    .cache_inst_rdata(cache_inst_rdata),
    .cache_inst_addr_ok(cache_inst_addr_ok) ,.cache_inst_data_ok(cache_inst_data_ok)
);
bridge_2x1 bridge_2x1(
    .no_dcache(no_dcache),
    //过cache后的data请求
    .cache_data_req(cache_data_req),    .cache_data_wr(cache_data_wr),
    .cache_data_size(cache_data_size),  .cache_data_addr(cache_data_addr),
    .cache_data_wdata(cache_data_wdata), 
    //过cache后的data回复
    .cache_data_rdata(cache_data_rdata),
    .cache_data_addr_ok(cache_data_addr_ok) ,.cache_data_data_ok(cache_data_data_ok),

    //不过cache的data请求
    .conf_data_req     (conf_data_req  ),     .conf_data_wr      (conf_data_wr   ),
    .conf_data_addr    (conf_data_addr ),     .conf_data_wdata   (conf_data_wdata),
    .conf_data_size    (conf_data_size ), 
    //不过cache得到的data回复
    .conf_data_rdata   (conf_data_rdata),
    .conf_data_addr_ok (conf_data_addr_ok),   .conf_data_data_ok (conf_data_data_ok),

    //合并
    .wrap_data_req     (wrap_data_req  ),     .wrap_data_wr      (wrap_data_wr   ),
    .wrap_data_addr    (wrap_data_addr ),     .wrap_data_wdata   (wrap_data_wdata),
    .wrap_data_size    (wrap_data_size ), 
    //合并
    .wrap_data_rdata   (wrap_data_rdata),
    .wrap_data_addr_ok (wrap_data_addr_ok),   .wrap_data_data_ok (wrap_data_data_ok)
);

cpu_axi_interface axi_interface(
    .clk(clk), .resetn(aresetn),
    //input
    .inst_req(cache_inst_req),    .inst_wr(cache_inst_wr),
    .inst_size(cache_inst_size),  .inst_addr(cache_inst_addr),
    .inst_wdata(cache_inst_wdata), 
    //output
    .inst_rdata(cache_inst_rdata),
    .inst_addr_ok(cache_inst_addr_ok) ,.inst_data_ok(cache_inst_data_ok) ,

    //input
    .data_req     (wrap_data_req  ),     .data_wr      (wrap_data_wr   ),
    .data_addr    (wrap_data_addr ),     .data_wdata   (wrap_data_wdata),
    .data_size    (wrap_data_size ), 
    //output
    .data_rdata   (wrap_data_rdata),
    .data_addr_ok (wrap_data_addr_ok),   .data_data_ok (wrap_data_data_ok),

    //input
    .arid(arid),            .araddr(araddr),   .arlen(arlen),
    .arsize(arsize),        .arburst(arburst), .arlock(arlock),
    .arcache(arcache),      .arprot(arprot),   .arvalid (arvalid),  
    //output
    .arready (arready),

    //input
    .rid(rid),              .rdata(rdata),     .rresp(rresp),
    .rlast(rlast),          .rvalid (rvalid),  
    //output
    .rready (rready),

    //input
    .awid(awid),            .awaddr(awaddr),   .awlen(awlen),
    .awsize(awsize),        .awburst(awburst), .awlock(awlock),
    .awcache(awcache),      .awprot(awprot),   .awvalid (awvalid),  
    //output
    .awready (awready),   

    //input
    .wid(wid),              .wdata(wdata),     .wstrb(wstrb),
    .wlast(wlast),          .wvalid (wvalid),  
    //output
    .wready (wready), 

    //input
    .bid(bid),              .bresp(bresp),     .bvalid (bvalid),  
    //output
    .bready (bready)
);

    //ascii
    //use for debug
    instdec instdec(
        .instr(cpu_inst_rdata)
    );

endmodule