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
    output wire[31:0] debug_wb_rf_wdata,
    // soc-simulator + cemu debug interface
    output wire [31:0] debug_cp0_count,
    output wire [31:0] debug_cp0_random,
    output wire [31:0] debug_cp0_cause,
    output wire debug_int,
    output wire debug_commit
);
    wire rst,clk;
    wire no_cache_i;
    wire no_cache_d;
    assign clk=aclk;
    assign rst=~aresetn;
    //inst
    wire [31:0]   virtual_instr_addrF;  //指令地址
    wire          cpu_inst_en;  //使能
    wire          i_stall;
    //TLB指令
    wire stallF2,stallM,flushM;
	wire TLBP;
	wire TLBR;
    wire TLBWI;
    wire TLBWR;
    wire [31:0] EntryHi_from_cp0;
	wire [31:0] PageMask_from_cp0;
	wire [31:0] EntryLo0_from_cp0;
	wire [31:0] EntryLo1_from_cp0;
	wire [31:0] Index_from_cp0;
	wire [31:0] Random_from_cp0;
	wire [31:0] EntryHi_to_cp0;
	wire [31:0] PageMask_to_cp0;
	wire [31:0] EntryLo0_to_cp0;
	wire [31:0] EntryLo1_to_cp0;
	wire [31:0] Index_to_cp0;
        //异常
    wire inst_tlb_refill, inst_tlb_invalid;
    wire data_tlb_refill, data_tlb_invalid, data_tlb_modify;
    wire mem_read_enM, mem_write_enM;
    //data
    wire        cpu_data_en;                    
    wire [31:0] virtual_data_addrM;     //写地址
    wire [3 :0] data_sram_wen;      //写使能
    wire         d_stall, icache_Ctl, alu_stallE;
    //cpu
    wire [31:0] cpu_inst_addr ;
    wire [31:0] cpu_inst1_rdata;
    wire [31:0] cpu_inst2_rdata;

    wire [31:0] cpu_data_addr ;
    wire cpu_data_wr   ;
    wire [1:0]  cpu_data_size ;
    wire [31:0] cpu_data_wdata;
    wire [31:0] cpu_data_rdata;

   //i_cache - arbitrater
    wire [31:0] i_araddr;
    wire [7:0]  i_arlen;
    wire        i_arvalid;
    wire        i_arready;
    wire [2:0]  i_arsize;

    wire [31:0] i_rdata;
    wire        i_rlast;
    wire        i_rvalid;
    wire        i_rready;

    //d_cache - arbitrater
    wire [31:0] d_araddr;
    wire [7:0]  d_arlen;
    wire [2:0]  d_arsize;
    wire        d_arvalid;
    wire        d_arready;
    wire [6:0]  cacheM;
    wire [6:0]  cacheE;

    wire[31:0]  d_rdata;
    wire        d_rlast;
    wire        d_rvalid;
    wire        d_rready;

    wire [31:0] d_awaddr;
    wire [7:0]  d_awlen;
    wire [2:0]  d_awsize;
    wire        d_awvalid;
    wire        d_awready;

    wire [31:0] d_wdata;
    wire [3:0]  d_wstrb;
    wire        d_wlast;
    wire        d_wvalid;
    wire        d_wready;

    wire        d_bvalid;
    wire        d_bready;
    wire [19:0] inst_pfn, data_pfn;
    wire inst_en_tmp;
    wire [31:0] aluoutE;

    datapath DataLine(
		.clk(clk),.rst(rst),
		.ext_int(ext_int),
        //instruction
    	.PC_IF1(virtual_instr_addrF), .inst_enF(cpu_inst_en), 
        .instrF2(cpu_inst1_rdata),
        .i_cache_stall(i_stall),
        //data
    	.mem_addrM(virtual_data_addrM),
    	.aluoutE(aluoutE),
        
        .mem_enM(cpu_data_en),
        .mem_rdataM2(cpu_data_rdata),
        .mem_write_selectM(data_sram_wen),.writedataM(cpu_data_wdata),
        .d_cache_stall(d_stall),
        .cpu_data_size(cpu_data_size),
        
        .alu_stallE(alu_stallE), .icache_Ctl(icache_Ctl),
        .stallF2(stallF2), .stallM(stallM), .flushM(flushM),
        //TLB
        .TLBP(TLBP),
        .TLBR(TLBR),
        .TLBWI(TLBWI),
        .TLBWR(TLBWR),

        .EntryHi_from_cp0(EntryHi_from_cp0),
        .PageMask_from_cp0(PageMask_from_cp0),
        .EntryLo0_from_cp0(EntryLo0_from_cp0),
        .EntryLo1_from_cp0(EntryLo1_from_cp0),
        .Index_from_cp0(Index_from_cp0),
        .Random_from_cp0(Random_from_cp0),

        .EntryHi_to_cp0(EntryHi_to_cp0),
        .PageMask_to_cp0(PageMask_to_cp0),
        .EntryLo0_to_cp0(EntryLo0_to_cp0),
        .EntryLo1_to_cp0(EntryLo1_to_cp0),
        .Index_to_cp0(Index_to_cp0),
            //异常
        .inst_tlb_refillF(inst_tlb_refill), .inst_tlb_invalidF(inst_tlb_invalid),
        .data_tlb_refillM(data_tlb_refill),
        .data_tlb_invalidM(data_tlb_invalid),
        .data_tlb_modifyM(data_tlb_modify),
        .mem_read_enM(mem_read_enM), .mem_write_enM(mem_write_enM),
		//debug interface
		.debug_wb_pc(debug_wb_pc), .debug_wb_rf_wen(debug_wb_rf_wen),
        .debug_wb_rf_wnum(debug_wb_rf_wnum), .debug_wb_rf_wdata(debug_wb_rf_wdata),
        .debug_cp0_count( debug_cp0_count),
        .debug_cp0_random( debug_cp0_random),
        .debug_cp0_cause( debug_cp0_cause),
        .debug_int( debug_int),
        .debug_commit( debug_commit)
	);

    // mmu Mmu_Trans(.inst_vaddr(virtual_instr_addrF), .inst_paddr(cpu_inst_addr),
    //             .data_vaddr(virtual_data_addrM), .data_paddr(cpu_data_addr),
    //             .data_sram_en(cpu_data_en),.data_sram_wen(data_sram_wen),
    //             .data_wr(cpu_data_wr), .data_size(cpu_data_size), .no_dcache(no_cache));
    assign cpu_data_wr = cpu_data_en & |data_sram_wen;
    tlb tlb0(
        .clk(clk), .rst(rst),
        .stallM(stallM), .flushM(flushM),
        .stallF(stallF2),
        //datapath
        .inst_vaddr(virtual_instr_addrF),
        .data_vaddr(aluoutE),

        .inst_en(cpu_inst_en),
        .mem_read_enM(mem_read_enM), .mem_write_enM(mem_write_enM),
        //cache
        
        // .inst_paddr(pcF_paddr),
        // .data_paddr(data_paddr),
        .inst_pfn(inst_pfn),
        .data_pfn(data_pfn),
        .no_cache_i(no_cache_i),
        .no_cache_d(no_cache_d),
        //异常
        .inst_tlb_refill(inst_tlb_refill),
        .inst_tlb_invalid(inst_tlb_invalid),
        .data_tlb_refill(data_tlb_refill),
        .data_tlb_invalid(data_tlb_invalid),
        .data_tlb_modify(data_tlb_modify),

        //TLB指令
        .TLBP(TLBP),
        .TLBR(TLBR),
        .TLBWI(TLBWI),
        .TLBWR(TLBWR),
        
        .EntryHi_in(EntryHi_from_cp0),
        .PageMask_in(PageMask_from_cp0),
        .EntryLo0_in(EntryLo0_from_cp0),
        .EntryLo1_in(EntryLo1_from_cp0),
        .Index_in(Index_from_cp0),
        .Random_in(Random_from_cp0),

        .EntryHi_out(EntryHi_to_cp0),
        .PageMask_out(PageMask_to_cp0),
        .EntryLo0_out(EntryLo0_to_cp0),
        .EntryLo1_out(EntryLo1_to_cp0),
        .Index_out(Index_to_cp0)
    );

    d_cache d_cache (
        //to do
        .clk(clk), .rst(rst),
        .no_cache(no_cache_d), .d_stall(d_stall), .i_stall(i_stall), .alu_stallE(alu_stallE),
        .data_sram_wen(data_sram_wen),
        .cpu_data_wr(cpu_data_wr),     .cpu_data_wdata(cpu_data_wdata), 
        .cpu_data_size(cpu_data_size),  .cpu_data_addr(virtual_data_addrM),
        .data_pfn(data_pfn),

        .cpu_data_en(cpu_data_en),      .cpu_data_rdata(cpu_data_rdata),
        //D CACHE
        .d_araddr          (d_araddr ), .d_arlen           (d_arlen  ),
        .d_arsize          (d_arsize ), .d_arvalid         (d_arvalid),
        .d_arready         (d_arready),

        .d_rdata           (d_rdata ), .d_rlast           (d_rlast ),
        .d_rvalid          (d_rvalid), .d_rready          (d_rready),

        .d_awaddr          (d_awaddr ), .d_awlen           (d_awlen  ),
        .d_awsize          (d_awsize ), .d_awvalid         (d_awvalid),
        .d_awready         (d_awready),

        .d_wdata           (d_wdata ), .d_wstrb           (d_wstrb ),
        .d_wlast           (d_wlast ), .d_wvalid          (d_wvalid),
        .d_wready          (d_wready),

        .d_bvalid          (d_bvalid), .d_bready          (d_bready)
    );

    i_cache i_cache(
        .clk(clk), .rst(rst),
        .no_cache(no_cache_i), .i_stall(i_stall), .icache_Ctl(icache_Ctl),
        
        .cpu_inst_en(cpu_inst_en),
        .cpu_inst_addr(virtual_instr_addrF),
        .inst_pfn(inst_pfn),
        .cpu_inst_rdata(cpu_inst1_rdata),
        //I CACHE OUTPUT
        .i_araddr          (i_araddr ), .i_arlen           (i_arlen  ),
        .i_arsize          (i_arsize ), .i_arvalid         (i_arvalid),
        .i_arready         (i_arready),
                    
        .i_rdata           (i_rdata ),  .i_rlast           (i_rlast ),
        .i_rvalid          (i_rvalid),  .i_rready          (i_rready)
    );




    cpu_axi_interface axi_interface(
        .clk(clk),          .rst(rst),
    //I CACHE
        .i_araddr          (i_araddr ), .i_arlen           (i_arlen  ),
        .i_arsize          (i_arsize ), .i_arvalid         (i_arvalid),
        .i_arready         (i_arready),
                    
        .i_rdata           (i_rdata ),  .i_rlast           (i_rlast ),
        .i_rvalid          (i_rvalid),  .i_rready          (i_rready),
        
    //D CACHE
        .d_araddr          (d_araddr ), .d_arlen           (d_arlen  ),
        .d_arsize          (d_arsize ), .d_arvalid         (d_arvalid),
        .d_arready         (d_arready),

        .d_rdata           (d_rdata ), .d_rlast           (d_rlast ),
        .d_rvalid          (d_rvalid), .d_rready          (d_rready),

        .d_awaddr          (d_awaddr ), .d_awlen           (d_awlen  ),
        .d_awsize          (d_awsize ), .d_awvalid         (d_awvalid),
        .d_awready         (d_awready),

        .d_wdata           (d_wdata ), .d_wstrb           (d_wstrb ),
        .d_wlast           (d_wlast ), .d_wvalid          (d_wvalid),
        .d_wready          (d_wready),

        .d_bvalid          (d_bvalid), .d_bready          (d_bready),

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
    instdec instdec1(
        .instr(cpu_inst1_rdata)
    );
    // instdec instdec2(
    //     .instr(cpu_inst2_rdata)
    // );

endmodule