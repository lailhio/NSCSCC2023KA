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
    //Cache配置
    parameter  INDEX_WIDTH  = 10, OFFSET_WIDTH = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    localparam DATA_WIDTH   = 32;

    //Cache存储单元，四路组相联，所以cache[3:0]
    (*ram_style="block"*) reg [1:0]               cache_valid [CACHE_DEEPTH - 1 : 0];
    (*ram_style="block"*) reg [1:0]               cache_dirty [CACHE_DEEPTH - 1 : 0]; // 是否被修改了，即是否脏了
    (*ram_style="block"*) reg [1:0]               cache_ru    [CACHE_DEEPTH - 1 : 0]; //* recently used    
    (*ram_style="block"*) reg [2*TAG_WIDTH-1:0]   cache_tag   [CACHE_DEEPTH - 1 : 0];
    (*ram_style="block"*) reg [2*DATA_WIDTH-1:0]  cache_block [CACHE_DEEPTH - 1 : 0];

    //访问地址分解
    wire [OFFSET_WIDTH-1:0] offset;
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    
    assign offset = cpu_inst_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_inst_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_inst_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];

    //访问Cache line
    wire                 c_valid[1:0];
    wire                 c_dirty[1:0]; // 是否修改过
    wire                 c_ru   [1:0]; //* recently used
    wire [TAG_WIDTH-1:0] c_tag  [1:0];
    wire [31:0]          c_block[1:0];

    assign c_valid[0] = cache_valid[index][0];
    assign c_valid[1] = cache_valid[index][1];

    assign c_dirty[0] = cache_dirty[index][0];
    assign c_dirty[1] = cache_dirty[index][1];

    assign c_ru   [0] = cache_ru   [index][0];
    assign c_ru   [1] = cache_ru   [index][1];

    assign c_tag  [0] = cache_tag  [index][1*TAG_WIDTH-1:0*TAG_WIDTH];
    assign c_tag  [1] = cache_tag  [index][2*TAG_WIDTH-1:1*TAG_WIDTH];

    assign c_block[0] = cache_block[index][1*DATA_WIDTH-1:0*DATA_WIDTH];
    assign c_block[1] = cache_block[index][2*DATA_WIDTH-1:1*DATA_WIDTH];

    //判断是否命中
    wire hit, miss;
    assign hit = c_valid[0] & (c_tag[0] == tag) | 
                 c_valid[1] & (c_tag[1] == tag);  //* cache line某一路中的valid位为1，且tag与地址中tag相等
    assign miss = ~hit;
    wire [1:0] c_way;
    //* 1. hit，选hit的那一路
    //* 2. miss，选不是最近使用的那一路(c_ru[0]==1，0路最近使用 -> c_way=1路)
    assign c_way = hit ? (c_valid[0] & (c_tag[0] == tag) ? 1'b0 : 1'b1) : 
                   c_ru[0] ? 1'b1 : 1'b0; 

    wire load, store;
    assign store = cpu_inst_wr;
    assign load = cpu_inst_req & ~store; // 是数据请求，且不是store，那么就是load
    //* cache当前位置是否dirty
    wire dirty, clean;
    assign dirty = c_dirty[c_way];
    assign clean = ~dirty;
    //FSM
    parameter IDLE = 2'b00, RM = 2'b01, WM = 2'b11;
    reg [1:0] state;
    // store指令，是否是处在RM状态（发生了miss)。当RM结束时(state从RM->IDLE)的上升沿，in_RM读出来仍为1.
    reg in_RM;

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            in_RM <= 1'b0;
        end
        else begin
            case(state)
            // 按照状态机编写
                IDLE: begin
                    state <= IDLE;
                    if (cpu_inst_req) begin
                        if (hit) 
                            state <= IDLE;
                        else if (miss & dirty)
                            state <= WM;
                        else if (miss & clean)
                            state <= RM;
                    end
                    in_RM <= 1'b0;
                end

                WM: begin
                    state <= WM;
                    if (cache_inst_data_ok)
                        state <= RM;
                end

                RM: begin
                    state <= RM;
                    if (cache_inst_data_ok)
                        state <= IDLE;

                    in_RM <= 1'b1;
                end
                default:begin
                    state <= IDLE;
                    in_RM <= 1'b0;
                end
            endcase
        end
    end

    //读内存
    //变量 isRM, addr_rcv, read_finish用于构造类sram信号。
    wire isRM;      //一次完整的读事务，从发出读请求到结束 // 是不是处于RM状态
    reg addr_rcv;       //地址接收成功(addr_ok)后到结束      // 处于RM状态，且地址已得到mem的确认
    wire read_finish;   //数据接收成功(data_ok)，即读请求结束 // 处于RM状态，且已得到mem读取的数据
    always @(posedge clk) begin
        addr_rcv <= rst ? 1'b0 :
                    cache_inst_req & isRM & cache_inst_addr_ok ? 1'b1 :
                    read_finish ? 1'b0 : 
                    addr_rcv;
    end
    assign isRM = state==RM;
    assign read_finish = isRM & cache_inst_data_ok;


    //output to mips core
    assign cpu_inst_rdata   = hit ? c_block[c_way] : cache_inst_rdata;
    assign cpu_inst_addr_ok = cpu_inst_req & hit | cache_inst_req & isRM & cache_inst_addr_ok;
    assign cpu_inst_data_ok = cpu_inst_req & hit | isRM & cache_inst_data_ok;

    //output to axi interface
    assign cache_inst_req   = isRM & ~addr_rcv;
    assign cache_inst_wr    = cpu_inst_wr;
    assign cache_inst_size  = cpu_inst_size;
    assign cache_inst_addr  = cache_inst_wr ? {c_tag[c_way], index, offset}:
                                              cpu_inst_addr;
    assign cache_inst_wdata = c_block[c_way];

    //写入Cache
    //保存地址中的tag, index，防止addr发生改变
    reg [TAG_WIDTH-1:0] tag_save;
    reg [INDEX_WIDTH-1:0] index_save;
    always @(posedge clk) begin
        tag_save   <= rst ? 0 :
                      cpu_inst_req ? tag : tag_save;
        index_save <= rst ? 0 :
                      cpu_inst_req ? index : index_save;
    end

    wire isIDLE = state==IDLE;

    integer t, y;
    always @(posedge clk) begin
        if(read_finish) begin // 处于RM状态，且已得到mem读取的数据
            case(c_way)
                1'b0: begin
                    cache_valid[index_save][0]<= 1'b1;  //将Cache line置为有效
                    cache_tag  [index_save][1*TAG_WIDTH-1:0*TAG_WIDTH] <= tag_save;
                    cache_block[index_save][1*DATA_WIDTH-1:0*DATA_WIDTH] <= cache_inst_rdata; //写入Cache line
                end
                1'b1: begin
                    cache_valid[index_save][1]<= 1'b1;  //将Cache line置为有效
                    cache_tag  [index_save][2*TAG_WIDTH-1:1*TAG_WIDTH] <= tag_save;
                    cache_block[index_save][2*DATA_WIDTH-1:1*DATA_WIDTH] <= cache_inst_rdata; //写入Cache line
                end
            endcase
        end
    end
endmodule
