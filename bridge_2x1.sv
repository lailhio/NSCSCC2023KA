module bridge_2x1 (
    input no_dcache,

    input         cache_data_req     ,
    input         cache_data_wr      ,
    input  [1 :0] cache_data_size    ,
    input  [31:0] cache_data_addr    ,
    input  [31:0] cache_data_wdata   ,
    output [31:0] cache_data_rdata   ,
    output        cache_data_addr_ok ,
    output        cache_data_data_ok ,

    input         conf_data_req     ,
    input         conf_data_wr      ,
    input  [1 :0] conf_data_size    ,
    input  [31:0] conf_data_addr    ,
    input  [31:0] conf_data_wdata   ,
    output [31:0] conf_data_rdata   ,
    output        conf_data_addr_ok ,
    output        conf_data_data_ok ,

    output        wrap_data_req     ,
    output        wrap_data_wr      ,
    output [1 :0] wrap_data_size    ,
    output [31:0] wrap_data_addr    ,
    output [31:0] wrap_data_wdata   ,
    input  [31:0] wrap_data_rdata   ,
    input         wrap_data_addr_ok ,
    input         wrap_data_data_ok
);

    assign cache_data_rdata   = no_dcache ? 0 : wrap_data_rdata  ;
    assign cache_data_addr_ok = no_dcache ? 0 : wrap_data_addr_ok;
    assign cache_data_data_ok = no_dcache ? 0 : wrap_data_data_ok;

    assign conf_data_rdata   = no_dcache ? wrap_data_rdata   : 0;
    assign conf_data_addr_ok = no_dcache ? wrap_data_addr_ok : 0;
    assign conf_data_data_ok = no_dcache ? wrap_data_data_ok : 0;

    assign wrap_data_req   = no_dcache ? conf_data_req   : cache_data_req  ;
    assign wrap_data_wr    = no_dcache ? conf_data_wr    : cache_data_wr   ;
    assign wrap_data_size  = no_dcache ? conf_data_size  : cache_data_size ;
    assign wrap_data_addr  = no_dcache ? conf_data_addr  : cache_data_addr ;
    assign wrap_data_wdata = no_dcache ? conf_data_wdata : cache_data_wdata;

endmodule