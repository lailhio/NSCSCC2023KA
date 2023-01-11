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
    
    //Cache存储单元
    //* 四路，所以cache扩大到四倍
    reg                 cache_valid [CACHE_DEEPTH - 1 : 0][3:0];
    reg                 cache_dirty [CACHE_DEEPTH - 1 : 0][3:0]; // 是否修改过
    reg [TAG_WIDTH-1:0] cache_tag   [CACHE_DEEPTH - 1 : 0][3:0];
    reg [31:0]          cache_block [CACHE_DEEPTH - 1 : 0][3:0];
    //* 伪LRU的查找树，对于 4 路的结构，每一个 cache set 需要 3bit 来存储最近使用信息。
    reg [2:0]           tree_table  [CACHE_DEEPTH - 1 : 0];
    //* tree 为对应cache set的查找树, tree[2]为根节点, tree[1]右子树，tree[0]左子树
    wire [2:0] tree;
    assign tree = tree_table[index];

    //访问地址分解
    wire [OFFSET_WIDTH-1:0] offset;
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    
    assign offset = cpu_inst_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_inst_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_inst_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];

    //访问Cache line
    wire                 c_valid[3:0];
    wire                 c_dirty[3:0]; // 是否修改过
    wire [TAG_WIDTH-1:0] c_tag  [3:0];
    wire [31:0]          c_block[3:0];

    assign c_valid[0] = cache_valid[index][0];
    assign c_valid[1] = cache_valid[index][1];
    assign c_valid[2] = cache_valid[index][2];
    assign c_valid[3] = cache_valid[index][3];
    assign c_dirty[0] = cache_dirty[index][0];
    assign c_dirty[1] = cache_dirty[index][1];
    assign c_dirty[2] = cache_dirty[index][2];
    assign c_dirty[3] = cache_dirty[index][3];
    assign c_tag  [0] = cache_tag  [index][0];
    assign c_tag  [1] = cache_tag  [index][1];
    assign c_tag  [2] = cache_tag  [index][2];
    assign c_tag  [3] = cache_tag  [index][3];
    assign c_block[0] = cache_block[index][0];
    assign c_block[1] = cache_block[index][1];
    assign c_block[2] = cache_block[index][2];
    assign c_block[3] = cache_block[index][3];

    //判断是否命中
    wire hit, miss;
    assign hit = c_valid[0] & (c_tag[0] == tag) | 
                 c_valid[1] & (c_tag[1] == tag) |
                 c_valid[2] & (c_tag[2] == tag) |
                 c_valid[3] & (c_tag[3] == tag);  //* cache line某一路中的valid位为1，且tag与地址中tag相等
    assign miss = ~hit;
     wire [1:0] c_way;
    //* 1. hit，选hit的那一路
    //* 2. miss，选伪LRU查找树索引出的最近未使用的那一路:
    //* 索引右子树: tree[2]==0 -> c_way = {tree[2], tree[1]}
    //* 索引左子树: tree[2]==1 -> c_way = {tree[2], tree[0]}  
    assign c_way = hit ? (c_valid[0] & (c_tag[0] == tag) ? 2'b00 :
                          c_valid[1] & (c_tag[1] == tag) ? 2'b01 :
                          c_valid[2] & (c_tag[2] == tag) ? 2'b10 :
                          2'b11) : 
                   tree[2] ? {tree[2], tree[0]} : //* 索引左子树w
                             {tree[2], tree[1]};  //* 索引右子树

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

    //写内存
    wire isWM;     // 是不是处于WM状态
    reg waddr_rcv;      // 处于WM状态，且地址已得到mem的确认
    wire write_finish;  // 处于WM状态，且已写入mem的数据
    always @(posedge clk) begin
        waddr_rcv <= rst ? 1'b0 :
                     cache_inst_req& isWM & cache_inst_addr_ok ? 1'b1 :
                     write_finish ? 1'b0 :
                     waddr_rcv;
    end
    assign isWM = state==WM;
    assign write_finish = isWM & cache_inst_data_ok;


    //output to mips core
    assign cpu_inst_rdata   = hit ? c_block[c_way] : cache_inst_rdata;
    assign cpu_inst_addr_ok = cpu_inst_req & hit | cache_inst_req & isRM & cache_inst_addr_ok;
    assign cpu_inst_data_ok = cpu_inst_req & hit | isRM & cache_inst_data_ok;

    //output to axi interface
    assign cache_inst_req   = isRM & ~addr_rcv | isWM & ~waddr_rcv;
    assign cache_inst_wr    = isWM;
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
    wire [31:0] write_cache_data;
    wire [3:0] write_mask;
//根据地址低两位和size，生成写掩码（针对sb，sh等不是写完整一个字的指令），4位对应1个字（4字节）中每个字的写使能
    assign write_mask = cpu_inst_size==2'b00 ?
                            (cpu_inst_addr[1] ? (cpu_inst_addr[0] ? 4'b1000 : 4'b0100):
                                                (cpu_inst_addr[0] ? 4'b0010 : 4'b0001)) :
                            (cpu_inst_size==2'b01 ? (cpu_inst_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111);

    //掩码的使用：位为1的代表需要更新的。
    //位拓展：{8{1'b1}} -> 8'b11111111
    //new_data = old_data & ~mask | write_data & mask
    assign write_cache_data = cache_block[index][c_way] & ~{{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}} | 
                              cpu_inst_wdata & {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}};

    wire isIDLE = state==IDLE;

    integer t, y;
    always @(posedge clk) begin
        if(rst) begin
            for(t=0; t<CACHE_DEEPTH; t=t+1) begin   //刚开始将Cache初始化为无效，dirty 初始化为 0
                for (y = 0; y<4; y=y+1) begin
                    cache_valid[t][y] = 0;
                    cache_dirty[t][y] = 0;
                end
                //* tree初始化为000
                tree_table[t] = 3'b000;
            end
        end
        else begin
            if(read_finish) begin // 处于RM状态，且已得到mem读取的数据
                cache_valid[index_save][c_way] <= 1'b1;             //将Cache line置为有效
                cache_dirty[index_save][c_way] <= 1'b0; // 读取内存的数据后，一定是clean
                cache_tag  [index_save][c_way] <= tag_save;
                cache_block[index_save][c_way] <= cache_inst_rdata; //写入Cache line
            end
            else if (store & isIDLE & (hit | in_RM)) begin 
                // store指令，hit进入IDLE状态 或 从读内存回到IDLE后，将寄存器值的(部分)字节写入cache对应行
                // 判断条件中加(hit | in_RM)是因为，如果只判断(store & isIDLE)，发生miss时，会在进入WM、RM之前提前进入该条件（本意是从RM回到IDLE的时候，已经读了mem的数据到cache后，再进入该条件，结果是刚进入store分支，就进入了该条件），
                // 如果提前进入条件的话，此时写入cache的write_cache_data为 {旧cache[:x], 寄存器[x-1:0]}，WM时会把这个错误数据写回mem，导致出错。为解决该问题，额外加了一个信号in_RM，记录之前是不是一直处在RM状态。
                cache_dirty[index][c_way] <= 1'b1; // 改了数据，变dirty
                cache_block[index][c_way] <= write_cache_data;      //写入Cache line，使用index而不是index_save
            end

            if ((load | store) & isIDLE & (hit | in_RM)) begin
                //* load 或 store指令，hit进入IDLE状态 或 从读内存回到IDLE后，更新伪LRU表
                //* 分析：
                //* c_way == 2'b00, 使用了way0，更新右子树，{tree[2], [1]} 更新为 2'b11;
                //* c_way == 2'b01, 使用了way1，更新右子树，{tree[2], [1]} 更新为 2'b10;
                //* c_way == 2'b10, 使用了way2，更新左子树，{tree[2], [0]} 更新为 2'b01;
                //* c_way == 2'b11, 使用了way3，更新左子树，{tree[2], [0]} 更新为 2'b00;
                if (c_way[1] == 1'b0)
                    {tree_table[index][2], tree_table[index][1]} <= ~c_way;
                else
                    {tree_table[index][2], tree_table[index][0]} <= ~c_way;
            end
        end
    end
endmodule