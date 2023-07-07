module i_cache (
    input wire clk, rst,
    //mips core
    input         cpu_inst_req     ,
    input         cpu_inst_wr      ,
    input  [1 :0] cpu_inst_size    ,
    input  [31:0] cpu_inst_addr    ,
    input  [31:0] cpu_inst_wdata   ,
    output [31:0] cpu_inst_rdata   ,
    output        cpu_inst_addr_ok ,
    output        cpu_inst_data_ok ,

    //axi interface
    output         cache_inst_req     ,
    output         cache_inst_wr      ,
    output  [1 :0] cache_inst_size    ,
    output  [31:0] cache_inst_addr    ,
    output  [31:0] cache_inst_wdata   ,
    input   [31:0] cache_inst_rdata   ,
    input          cache_inst_addr_ok ,
    input          cache_inst_data_ok 
);
    //Cache
    parameter  INDEX_WIDTH  = 10, OFFSET_WIDTH = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    localparam DATA_WIDTH   = 32;

    
    (*ram_style="block"*) reg [1:0]               cache_valid [CACHE_DEEPTH - 1 : 0];
    (*ram_style="block"*) reg [1:0]               cache_ru    [CACHE_DEEPTH - 1 : 0]; 

    
    wire [OFFSET_WIDTH-1:0] offset;
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    wire [1:0] wena_tag_ram_way;
    wire [1:0] wena_data_bank_way;
    assign offset = cpu_inst_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_inst_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_inst_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];
 
    reg                 c_valid[1:0];
    reg                 c_ru   [1:0]; //* recently used
    reg [TAG_WIDTH-1:0] c_tag  [1:0];
    reg [31:0]          c_block[1:0];
	
    always @(posedge clk) begin
        if(rst) begin
            c_valid[0] <= 0;
            c_valid[1] <= 0;
            c_ru[0] <= 0;
            c_ru[1] <= 0;
        end
        else begin
            c_valid[0] <= cache_valid[index][0];
            c_valid[1] <= cache_valid[index][1];
            c_ru   [0] <= cache_ru   [index][0];
            c_ru   [1] <= cache_ru   [index][1];
        end
    end
    
    wire hit, miss;
    wire [1:0] c_way;
    wire way;
    assign way = hit ? c_way[1] : c_ru[1];
    assign hit = |c_way;  //* cache line
    assign miss = ~hit;
    //* 1. hit
    //* 2. miss
    assign c_way[0] = c_valid[0] & c_tag[0] == tag;
    assign c_way[1] = c_valid[1] & c_tag[1] == tag;

    //FSM
    parameter IDLE = 2'b00, RM = 2'b01;
    reg [1:0] state;
    // store
    // reg in_RM;

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            // in_RM <= 1'b0;
        end
        else begin
            case(state)
                IDLE: begin
                    state <= IDLE;
                    if (cpu_inst_req) begin
                        if (hit) 
                            state <= IDLE;
                        else if (miss)
                            state <= RM;
                    end
                    // in_RM <= 1'b0;
                end

                RM: begin
                    state <= RM;
                    if (cache_inst_data_ok)
                        state <= IDLE;

                    // in_RM <= 1'b1;
                end
                default:begin
                    state <= IDLE;
                    // in_RM <= 1'b0;
                end
            endcase
        end
    end


    wire isRM;    
    reg addr_rcv;       
    wire read_finish;   
    always @(posedge clk) begin
        addr_rcv <= rst ? 1'b0 :
                    cache_inst_req & isRM & cache_inst_addr_ok ? 1'b1 :
                    read_finish ? 1'b0 : 
                    addr_rcv;
    end
    assign isRM = state==RM;
    assign read_finish = isRM & cache_inst_data_ok;


    //output to mips core
    assign cpu_inst_rdata   = hit ? c_block[way] : cache_inst_rdata;
    assign cpu_inst_addr_ok = cpu_inst_req & hit | cache_inst_req & isRM & cache_inst_addr_ok;
    assign cpu_inst_data_ok = cpu_inst_req & hit | isRM & cache_inst_data_ok;

    //output to axi interface
    assign cache_inst_req   = isRM & ~addr_rcv;
    assign cache_inst_wr    = cpu_inst_wr;
    assign cache_inst_size  = cpu_inst_size;
    assign cache_inst_addr  = cache_inst_wr ? {c_tag[way], index, offset}:
                                              cpu_inst_addr;
    assign cache_inst_wdata = c_block[way];

    reg [TAG_WIDTH-1:0] tag_save;
    reg [INDEX_WIDTH-1:0] index_save;
    always @(posedge clk) begin
        tag_save   <= rst ? 0 :
                      cpu_inst_req ? tag : tag_save;
        index_save <= rst ? 0 :
                      cpu_inst_req ? index : index_save;
    end

    wire isIDLE = state==IDLE;
    assign wena_tag_ram_way = {2{read_finish}} & c_way;
    wire [1:0] wena_data_bank_way;
    assign wena_data_bank_way = {2{read_finish}} & c_way;
    integer t, y;
    always @(posedge clk) begin
        if(read_finish) begin 
            cache_valid[index_save] <= c_way;
        end
        if (hit | read_finish) begin
            cache_ru[index]   <= c_way; //* c_way 
        end
    end
    
    genvar i;
    generate
        for (i=0;i<2;i++)begin
            tag_ram i_tag
            (
            .clka   (clk),
            .clkb   (clk),
            .ena    (wena_tag_ram_way[i]),
            .enb    (1'b1),
            .addra  (index_save),
            .dina   (tag_save),
            .wea    (wena_tag_ram_way[i]),
            .addrb  (index),
            .doutb  (c_tag[i])
            );
            cache_block_ram i_data
            (
            .clka   (clk),
            .clkb   (clk),
            .ena    (wena_data_bank_way[i]),
            .enb    (1'b1),
            .addra  (index_save),
            .dina   (cache_inst_rdata),
            .wea    (wena_data_bank_way[i]),
            .addrb  (index),
            .doutb  (c_block[i])
            );
        end
    endgenerate
endmodule
