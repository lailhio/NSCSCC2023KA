module cpu_axi_interface
(
    input wire clk, rst,
    //I CACHE
    input wire [31:0] i_araddr,
    input wire [7:0] i_arlen,
    input wire [2:0] i_arsize,
    input wire       i_arvalid,
    output wire      i_arready,

    output wire [31:0] i_rdata,
    output wire        i_rlast,
    output wire        i_rvalid,
    input wire         i_rready,

    //D CACHE
    input wire [31:0] d_araddr,
    input wire [7:0] d_arlen,
    input wire [2:0] d_arsize,
    input wire       d_arvalid,
    output wire      d_arready,

    output wire [31:0] d_rdata,
    output wire        d_rlast,
    output wire        d_rvalid,
    input wire         d_rready,
    //write
    input wire [31:0] d_awaddr,
    input wire [7:0] d_awlen,
    input wire [2:0] d_awsize,
    input wire       d_awvalid,
    output wire      d_awready,
    
    input wire [31:0] d_wdata,
    input wire [3:0] d_wstrb,
    input wire       d_wlast,
    input wire       d_wvalid,
    output wire      d_wready,

    output wire      d_bvalid,
    input wire       d_bready,


    //axi
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock        ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       
);
    wire ar_sel;     //0 :i_cache, 1 : d_cache
    // reg [1:0] r_sel;      //2'b00-> no, 2'b01-> i_cache, 2'b10-> d_cache

    //ar
    assign ar_sel =  ~i_arvalid & d_arvalid ? 1'b1 : 1'b0;   
    wire r_sel;     //0-> i_cache, 1-> d_cache
    assign r_sel = rid[0];

    //D_CACHE
    assign d_arready = arready & ar_sel;
    assign d_rdata = r_sel ? rdata : 32'b0;
    assign d_rlast = r_sel ? rlast : 1'b0;
    assign d_rvalid = r_sel ? rvalid : 1'b0;

    //I_CACHE
    assign i_arready = arready & ~ar_sel;
    assign i_rdata = ~r_sel ? rdata : 32'b0;
    assign i_rlast = ~r_sel ? rlast : 1'b0;
    assign i_rvalid = ~r_sel ? rvalid : 1'b0;


    //AXI
    assign awid    = 4'd0;
    assign awaddr  = d_awaddr;
    assign awlen   = d_awlen;  
    assign awsize  = d_awsize;
    assign awburst = 2'b01; 
    assign awlock  = 2'd0;
    assign awcache = 4'd0;
    assign awprot  = 3'd0;
    assign awvalid = d_awvalid;
    //w
    assign wid    = 4'd0;
    assign wdata  = d_wdata;
    assign wstrb = d_wstrb;
    assign wlast  = d_wlast;
    assign wvalid = d_wvalid;
    //b
    assign bready  = d_bready;
    
    //to d-cache
    assign d_awready = awready;
    assign d_wready  = wready;
    assign d_bvalid  = bvalid;

    assign arid = {3'b0, ar_sel};
    assign araddr = ar_sel ? d_araddr : i_araddr;
    assign arlen = ar_sel ? d_arlen : i_arlen;
    assign arsize  = ar_sel ? d_arsize : i_arsize;
    assign arburst = 2'b01;  
    assign arlock  = 2'd0;
    assign arcache = 4'd0;
    assign arprot  = 3'd0;
    assign arvalid = ar_sel ? d_arvalid : i_arvalid;
    assign rready = ~r_sel ? i_rready : d_rready;
                        //            
endmodule

