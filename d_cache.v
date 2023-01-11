module d_cache (
    input wire clk, rst,
    //mips core
    input         cpu_data_req     ,
    input         cpu_data_wr      ,
    input  [1 :0] cpu_data_size    ,
    input  [31:0] cpu_data_addr    ,
    input  [31:0] cpu_data_wdata   ,
    output [31:0] cpu_data_rdata   ,
    output        cpu_data_addr_ok ,
    output        cpu_data_data_ok ,

    //axi interface
    output         cache_data_req     ,
    output         cache_data_wr      ,
    output  [1 :0] cache_data_size    ,
    output  [31:0] cache_data_addr    ,
    output  [31:0] cache_data_wdata   ,
    input   [31:0] cache_data_rdata   ,
    input          cache_data_addr_ok ,
    input          cache_data_data_ok 
);
    //Cache配置
    parameter  INDEX_WIDTH  = 10, OFFSET_WIDTH = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    localparam DATA_WIDTH   = 32;
    
    //访问地址分解
    wire [OFFSET_WIDTH-1:0] offset;
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    
    assign offset = cpu_data_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_data_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_data_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];

    //Cache存储单元，四路组相联，所以cache[3:0]
    reg [3:0]               cache_valid [CACHE_DEEPTH - 1 : 0];
    reg [3:0]               cache_dirty [CACHE_DEEPTH - 1 : 0]; // 是否被修改了，即是否脏了
    reg [4*TAG_WIDTH-1:0]   cache_tag   [CACHE_DEEPTH - 1 : 0];
    reg [4*DATA_WIDTH-1:0]  cache_block [CACHE_DEEPTH - 1 : 0];
    // 伪LRU的查找树，对于 4 路的结构，每一个 cache set 需要 3bit 来存储最近使用信息。
    reg [2:0]           tree_table  [CACHE_DEEPTH - 1 : 0];
    // tree 为对应cache set的查找树, tree[2]为根节点, tree[1]右子树，tree[0]左子树
    wire [2:0] tree;
    assign tree = tree_table[index];

    //访问Cache line
    wire                 c_valid[3:0];
    wire                 c_dirty[3:0]; 
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

    assign c_tag  [0] = cache_tag  [index][1*TAG_WIDTH-1:0*TAG_WIDTH];
    assign c_tag  [1] = cache_tag  [index][2*TAG_WIDTH-1:1*TAG_WIDTH];
    assign c_tag  [2] = cache_tag  [index][3*TAG_WIDTH-1:2*TAG_WIDTH];
    assign c_tag  [3] = cache_tag  [index][4*TAG_WIDTH-1:3*TAG_WIDTH];

    assign c_block[0] = cache_block[index][1*DATA_WIDTH-1:0*DATA_WIDTH];
    assign c_block[1] = cache_block[index][2*DATA_WIDTH-1:1*DATA_WIDTH];
    assign c_block[2] = cache_block[index][3*DATA_WIDTH-1:2*DATA_WIDTH];
    assign c_block[3] = cache_block[index][4*DATA_WIDTH-1:3*DATA_WIDTH];

    //判断是否命中
    wire hit, miss;
    assign hit = c_valid[0] & (c_tag[0] == tag) | 
                 c_valid[1] & (c_tag[1] == tag) |
                 c_valid[2] & (c_tag[2] == tag) |
                 c_valid[3] & (c_tag[3] == tag);  // cache line某一路中的valid位为1，且tag与地址中tag相等
    assign miss = ~hit;

    // 后面的cache处理应访问哪一路
    wire [1:0] c_way;
    // 1. hit，选hit的那一路
    // 2. miss，选伪LRU查找树索引出的最近未使用的那一路:
    // 索引右子树: tree[2]==0 -> c_way = {tree[2], tree[1]}
    // 索引左子树: tree[2]==1 -> c_way = {tree[2], tree[0]}  
    assign c_way = hit ? (c_valid[0] & (c_tag[0] == tag) ? 2'b00 :
                          c_valid[1] & (c_tag[1] == tag) ? 2'b01 :
                          c_valid[2] & (c_tag[2] == tag) ? 2'b10 :
                          2'b11) : 
                   tree[2] ? {tree[2], tree[0]} : // 索引左子树
                             {tree[2], tree[1]};  // 索引右子树

    // read or write
    wire read, write;
    assign write = cpu_data_wr;
    assign read =  ~write; 

    // cache当前位置是否dirty
    wire dirty, clean;
    assign dirty = c_dirty[c_way];
    assign clean = ~dirty;

    //FSM
    parameter IDLE = 2'b00, RM = 2'b01, WM = 2'b11;
    reg [1:0] state;
    // write指令，是否是处在RM状态（发生了miss)。当RM结束时(state从RM->IDLE)的上升沿，in_RM读出来仍为1.
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
                    if (cpu_data_req) begin
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
                    if (cache_data_data_ok)
                        state <= RM;
                end

                RM: begin
                    state <= RM;
                    if (cache_data_data_ok)
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
    //变量 read_req, addr_rcv, read_finish用于构造类sram信号。
    wire read_req;      //一次完整的读事务，从发出读请求到结束
    reg addr_rcv;       //地址接收成功(addr_ok)后到结束      
    wire read_finish;   //数据接收成功(data_ok)，即读请求结束
    always @(posedge clk) begin
        addr_rcv <= rst ? 1'b0 :
                    cache_data_req & read_req & cache_data_addr_ok ? 1'b1 :
                    read_finish ? 1'b0 : addr_rcv;
    end
    assign read_req = state==RM;
    assign read_finish = read_req & cache_data_data_ok;

    //写内存
    wire write_req;     // 是不是处于WM状态
    reg waddr_rcv;      // 处于WM状态，且地址已得到mem的确认
    wire write_finish;  // 处于WM状态，且已写入mem的数据
    always @(posedge clk) begin
        waddr_rcv <= rst ? 1'b0 :
                     cache_data_req& write_req & cache_data_addr_ok ? 1'b1 :
                     write_finish ? 1'b0 : waddr_rcv;
    end
    assign write_req = state==WM;
    assign write_finish = write_req & cache_data_data_ok;

    //output to mips core
    assign cpu_data_rdata   = hit ? c_block[c_way] : cache_data_rdata;
    assign cpu_data_addr_ok = cpu_data_req & hit | cache_data_req & read_req & cache_data_addr_ok;
    assign cpu_data_data_ok = cpu_data_req & hit | read_req & cache_data_data_ok;

    //output to axi interface
    assign cache_data_req   = read_req & ~addr_rcv | write_req & ~waddr_rcv;
    assign cache_data_wr    = write_req;
    assign cache_data_size  = cpu_data_size;
    // 如果要写内存，写回mem的地址为原cache line对应的地址（旧地址）
    // 如果是读内存，对应mem的地址为cpu_data_addr（新地址）
    assign cache_data_addr  = cache_data_wr ? {c_tag[c_way], index, offset}:
                                              cpu_data_addr;
    // cache要写回memory的数据是原cache line的数据
    assign cache_data_wdata = c_block[c_way];

    //写入Cache
    //保存地址中的tag, index，防止addr发生改变
    reg [TAG_WIDTH-1:0] tag_save;
    reg [INDEX_WIDTH-1:0] index_save;
    always @(posedge clk) begin
        tag_save   <= rst ? 0 :
                      cpu_data_req ? tag : tag_save;
        index_save <= rst ? 0 :
                      cpu_data_req ? index : index_save;
    end

    wire [31:0] write_cache_data;
    wire [3:0] write_mask;

    //根据地址低两位和size，生成写掩码（针对sb，sh等不是写完整一个字的指令），4位对应1个字（4字节）中每个字的写使能
    assign write_mask = cpu_data_size==2'b00 ?
                            (cpu_data_addr[1] ? (cpu_data_addr[0] ? 4'b1000 : 4'b0100):
                                                (cpu_data_addr[0] ? 4'b0010 : 4'b0001)) :
                            (cpu_data_size==2'b01 ? (cpu_data_addr[1] ? 4'b1100 : 4'b0011) : 4'b1111);

    //掩码的使用：位为1的代表需要更新的。
    //位拓展：{8{1'b1}} -> 8'b11111111
    //new_data = old_data & ~mask | write_data & mask
    wire [31:0] cache_tmp;
    assign cache_tmp=   (~|(c_way^2'b00)) ?cache_block[index][1*DATA_WIDTH-1:0*DATA_WIDTH]:
                        ( (~|(c_way^2'b01))? cache_block[index][2*DATA_WIDTH-1:1*DATA_WIDTH]:
                            ((~|(c_way^2'b10))? cache_block[index][3*DATA_WIDTH-1:2*DATA_WIDTH]:
                                                    cache_block[index][4*DATA_WIDTH-1:3*DATA_WIDTH]));


    assign write_cache_data = cache_tmp & ~{{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}} | 
                              cpu_data_wdata & {{8{write_mask[3]}}, {8{write_mask[2]}}, {8{write_mask[1]}}, {8{write_mask[0]}}};

    wire isIDLE = state==IDLE;

    integer t, y;
    always @(posedge clk) begin
        if(rst) begin
            for(t=0; t<CACHE_DEEPTH; t=t+1) begin   //刚开始将Cache初始化为无效，dirty 初始化为 0
                for (y = 0; y<4; y=y+1) begin
                    cache_valid[t][y] = 0;
                    cache_dirty[t][y] = 0;
                end
                // tree初始化为000
                tree_table[t] = 3'b000;
            end
        end
        else begin
            if(read_finish) begin // 处于RM状态，且已得到mem读取的数据
                case(c_way)
                    2'b00: begin
                        cache_valid[index_save][0]<= 1'b1;  //将Cache line置为有效
                        cache_dirty[index_save][0] <= 1'b0;  // 读取内存的数据后，一定是clean
                        cache_tag  [index_save][1*TAG_WIDTH-1:0*TAG_WIDTH] <= tag_save;
                        cache_block[index_save][1*DATA_WIDTH-1:0*DATA_WIDTH] <= cache_data_rdata; //写入Cache line
                    end
                    2'b01: begin
                        cache_valid[index_save][1]<= 1'b1;  //将Cache line置为有效
                        cache_dirty[index_save][1] <= 1'b0;  // 读取内存的数据后，一定是clean
                        cache_tag  [index_save][2*TAG_WIDTH-1:1*TAG_WIDTH] <= tag_save;
                        cache_block[index_save][2*DATA_WIDTH-1:1*DATA_WIDTH] <= cache_data_rdata; //写入Cache line
                    end
                    2'b10: begin
                        cache_valid[index_save][2]<= 1'b1;  //将Cache line置为有效
                        cache_dirty[index_save][2] <= 1'b0;  // 读取内存的数据后，一定是clean
                        cache_tag  [index_save][3*TAG_WIDTH-1:2*TAG_WIDTH] <= tag_save;
                        cache_block[index_save][3*DATA_WIDTH-1:2*DATA_WIDTH] <= cache_data_rdata; //写入Cache line
                    end
                    2'b11: begin
                        cache_valid[index_save][3]<= 1'b1;  //将Cache line置为有效
                        cache_dirty[index_save][3] <= 1'b0;  // 读取内存的数据后，一定是clean
                        cache_tag  [index_save][4*TAG_WIDTH-1:3*TAG_WIDTH] <= tag_save;
                        cache_block[index_save][4*DATA_WIDTH-1:3*DATA_WIDTH] <= cache_data_rdata; //写入Cache line
                    end
                endcase
            end
            else if (write & isIDLE & (hit | in_RM)) begin 
                // write指令，hit进入IDLE状态 或 从读内存回到IDLE后，将寄存器值的(部分)字节写入cache对应行
                // 判断条件中加(hit | in_RM)是因为，如果只判断(write & isIDLE)，发生miss时，会在进入WM、RM之前提前进入该条件（本意是从RM回到IDLE的时候，已经读了mem的数据到cache后，再进入该条件，结果是刚进入write分支，就进入了该条件），
                // 如果提前进入条件的话，此时写入cache的write_cache_data为 {旧cache[:x], 寄存器[x-1:0]}，WM时会把这个错误数据写回mem，导致出错。为解决该问题，额外加了一个信号in_RM，记录之前是不是一直处在RM状态。
                case(c_way)
                    2'b00: begin
                        cache_dirty[index][0]                        <= 1'b1; // 改了数据，变dirty
                        cache_block[index][1*DATA_WIDTH-1:0*DATA_WIDTH]<= write_cache_data;  
                    end
                    2'b01: begin
                        cache_dirty[index][1]                        <= 1'b1; // 改了数据，变dirty
                        cache_block[index][2*DATA_WIDTH-1:1*DATA_WIDTH]<= write_cache_data;  
                    end
                    2'b10: begin
                        cache_dirty[index][2]                        <= 1'b1; // 改了数据，变dirty
                        cache_block[index][3*DATA_WIDTH-1:2*DATA_WIDTH]<= write_cache_data;  
                    end
                    2'b11: begin
                        cache_dirty[index][3]                        <= 1'b1; // 改了数据，变dirty
                        cache_block[index][4*DATA_WIDTH-1:3*DATA_WIDTH]<= write_cache_data;  
                    end
                endcase
            end

            if ((read | write) & isIDLE & (hit | in_RM)) begin
                // read 或 write指令，hit进入IDLE状态 或 从读内存回到IDLE后，更新伪LRU表
                // 分析：
                // c_way == 2'b00, 使用了way0，更新右子树，{tree[2], [1]} 更新为 2'b11;
                // c_way == 2'b01, 使用了way1，更新右子树，{tree[2], [1]} 更新为 2'b10;
                // c_way == 2'b10, 使用了way2，更新左子树，{tree[2], [0]} 更新为 2'b01;
                // c_way == 2'b11, 使用了way3，更新左子树，{tree[2], [0]} 更新为 2'b00;
                if (c_way[1] == 1'b0)
                    {tree_table[index][2], tree_table[index][1]} <= ~c_way;
                else
                    {tree_table[index][2], tree_table[index][0]} <= ~c_way;
            end
        end
    end
endmodule