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
    //Cache閰嶇疆
    parameter  INDEX_WIDTH  = 10, OFFSET_WIDTH = 2;
    localparam TAG_WIDTH    = 32 - INDEX_WIDTH - OFFSET_WIDTH;
    localparam CACHE_DEEPTH = 1 << INDEX_WIDTH;
    localparam DATA_WIDTH   = 32;

    //Cache瀛樺偍鍗曞厓锛屽洓璺粍鐩歌仈锛屾墍浠ache[3:0]
    (*ram_style="block"*) reg [1:0]               cache_valid [CACHE_DEEPTH - 1 : 0];
    (*ram_style="block"*) reg [1:0]               cache_ru    [CACHE_DEEPTH - 1 : 0]; //* recently used    
//    (*ram_style="block"*) reg [2*TAG_WIDTH-1:0]   cache_tag   [CACHE_DEEPTH - 1 : 0];
//    (*ram_style="block"*) reg [2*DATA_WIDTH-1:0]  cache_block [CACHE_DEEPTH - 1 : 0];

    //璁块棶鍦板潃鍒嗚В
    wire [OFFSET_WIDTH-1:0] offset;
    wire [INDEX_WIDTH-1:0] index;
    wire [TAG_WIDTH-1:0] tag;
    wire [1:0] wena_tag_ram_way;
    wire [1:0] wena_data_bank_way;
    assign offset = cpu_inst_addr[OFFSET_WIDTH - 1 : 0];
    assign index = cpu_inst_addr[INDEX_WIDTH + OFFSET_WIDTH - 1 : OFFSET_WIDTH];
    assign tag = cpu_inst_addr[31 : INDEX_WIDTH + OFFSET_WIDTH];
    //璁块棶Cache line
    reg                 c_valid[1:0];
    reg                 c_ru   [1:0]; //* recently used
    reg [TAG_WIDTH-1:0] c_tag  [1:0];
    reg [31:0]          c_block[1:0];
//    assign c_valid[0] = cache_valid[index][0];
//    assign c_valid[1] = cache_valid[index][1];

//    assign c_ru   [0] = cache_ru   [index][0];
//    assign c_ru   [1] = cache_ru   [index][1];
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
//    assign c_tag  [0] = cache_tag  [index][1*TAG_WIDTH-1:0*TAG_WIDTH];
//    assign c_tag  [1] = cache_tag  [index][2*TAG_WIDTH-1:1*TAG_WIDTH];

//    assign c_block[0] = cache_block[index][1*DATA_WIDTH-1:0*DATA_WIDTH];
//    assign c_block[1] = cache_block[index][2*DATA_WIDTH-1:1*DATA_WIDTH];
    
    //鍒ゆ柇鏄惁鍛戒腑
    wire hit, miss;
    wire [1:0] c_way;
    wire way;
    assign way = hit ? c_way[1] : c_ru[1];
    assign hit = |c_way;  //* cache line鏌愪竴璺腑鐨剉alid浣嶄负1锛屼笖tag涓庡湴鍧?涓璽ag鐩哥瓑
    assign miss = ~hit;
    //* 1. hit锛岄?塰it鐨勯偅涓?璺?
    //* 2. miss锛岄?変笉鏄渶杩戜娇鐢ㄧ殑閭ｄ竴璺?(c_ru[0]==1锛?0璺渶杩戜娇鐢? -> c_way=1璺?)
    assign c_way[0] = c_valid[0] & c_tag[0] == tag;
    assign c_way[1] = c_valid[1] & c_tag[1] == tag;

    //FSM
    parameter IDLE = 2'b00, RM = 2'b01;
    reg [1:0] state;
    // store鎸囦护锛屾槸鍚︽槸澶勫湪RM鐘舵?侊紙鍙戠敓浜唌iss)銆傚綋RM缁撴潫鏃?(state浠嶳M->IDLE)鐨勪笂鍗囨部锛宨n_RM璇诲嚭鏉ヤ粛涓?1.
    // reg in_RM;

    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            // in_RM <= 1'b0;
        end
        else begin
            case(state)
            // 鎸夌収鐘舵?佹満缂栧啓
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

    //璇诲唴瀛?
    //鍙橀噺 isRM, addr_rcv, read_finish鐢ㄤ簬鏋勯?犵被sram淇″彿銆?
    wire isRM;      //涓?娆″畬鏁寸殑璇讳簨鍔★紝浠庡彂鍑鸿璇锋眰鍒扮粨鏉? // 鏄笉鏄浜嶳M鐘舵??
    reg addr_rcv;       //鍦板潃鎺ユ敹鎴愬姛(addr_ok)鍚庡埌缁撴潫      // 澶勪簬RM鐘舵?侊紝涓斿湴鍧?宸插緱鍒癿em鐨勭‘璁?
    wire read_finish;   //鏁版嵁鎺ユ敹鎴愬姛(data_ok)锛屽嵆璇昏姹傜粨鏉? // 澶勪簬RM鐘舵?侊紝涓斿凡寰楀埌mem璇诲彇鐨勬暟鎹?
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

    //鍐欏叆Cache
    //淇濆瓨鍦板潃涓殑tag, index锛岄槻姝ddr鍙戠敓鏀瑰彉
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
        if(read_finish) begin // 澶勪簬RM鐘舵?侊紝涓斿凡寰楀埌mem璇诲彇鐨勬暟鎹?
            cache_valid[index_save] <= c_way;
//            if(c_way[0]) begin
//                    cache_valid[index_save][0]<= 1'b1;  //灏咰ache line缃负鏈夋晥
////                    cache_tag  [index_save][1*TAG_WIDTH-1:0*TAG_WIDTH] <= tag_save;
////                    cache_block[index_save][1*DATA_WIDTH-1:0*DATA_WIDTH] <= cache_inst_rdata; //鍐欏叆Cache line
//                end
//            else if(c_way[1]) begin
//                    cache_valid[index_save][1]<= 1'b1;  //灏咰ache line缃负鏈夋晥
////                    cache_tag  [index_save][2*TAG_WIDTH-1:1*TAG_WIDTH] <= tag_save;
////                    cache_block[index_save][2*DATA_WIDTH-1:1*DATA_WIDTH] <= cache_inst_rdata; //鍐欏叆Cache line
//                end
        end
        if (hit | read_finish) begin
            //* load 鎴? store鎸囦护锛宧it杩涘叆IDLE鐘舵?? 鎴? 浠庤鍐呭瓨鍥炲埌IDLE鍚庯紝灏嗘渶杩戜娇鐢ㄦ儏鍐垫洿鏂?
            cache_ru[index]   <= c_way; //* c_way 璺渶杩戜娇鐢ㄤ簡
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
