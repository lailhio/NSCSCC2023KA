module d_cache#(
    parameter LEN_LINE = 6,  // 32 Bytes
    parameter LEN_INDEX = 7, // 128 lines
    parameter NR_WAYS = 2
) (
    input wire clk, rst ,no_cache, i_stall, alu_stallE,
    output wire d_stall,
    input [3:0]   data_sram_wen,
    //mips core
    input         cpu_data_en     , 
    input         cpu_data_wr      , // whether is store type
    input  [1 :0] cpu_data_size    , // from the addr ,write size data 
    input  [31:0] cpu_data_addr    ,
    input  [31:0] cpu_data_wdata   ,
    output [31:0] cpu_data_rdata   ,

    //D CACHE
    output reg [31:0] d_araddr,
    output reg [7:0] d_arlen,
    output reg [2:0] d_arsize,
    output reg       d_arvalid,
    input wire        d_arready,

    input wire [31:0] d_rdata,
    input wire        d_rlast,
    input wire        d_rvalid,
    output reg         d_rready,
    //write
    output reg [31:0] d_awaddr,
    output reg [7:0] d_awlen,
    output reg [2:0] d_awsize,
    output reg       d_awvalid,
    input wire        d_awready,
    
    output reg [31:0] d_wdata,
    output reg [3:0] d_wstrb,
    output reg       d_wlast,
    output reg       d_wvalid,
    input wire        d_wready,

    input wire        d_bvalid,
    output wire       d_bready
);
    // defines
    localparam LEN_PER_WAY = LEN_LINE + LEN_INDEX;
    localparam LEN_TAG = 32 - LEN_LINE - LEN_INDEX;
    localparam LEN_BRAM_ADDR = LEN_LINE - 3 + LEN_INDEX;
    localparam CACHE_DEEPTH = 1 << LEN_INDEX;
    localparam NR_WORDS = 1 << (LEN_LINE - 2);
    //Cache
    localparam DATA_WIDTH   = 32;
    wire [LEN_LINE-1:0] ZeroBit = 0;
    //Cache存储单元
    //* 两路，所以cache扩大一倍
    (*ram_style="block"*) reg [1:0]             cache_valid [CACHE_DEEPTH - 1 : 0];
    (*ram_style="block"*) reg [1:0]             cache_dirty [CACHE_DEEPTH - 1 : 0]; // 是否修改过
    (*ram_style="block"*) reg [1:0]             cache_lru    [CACHE_DEEPTH - 1 : 0]; //* recently used


    // sys 
    wire data_wr_en;
    wire no_cache_res;
    wire data_en;
    wire [LEN_INDEX-1:0] index_Res;
    //addr part
    wire [LEN_LINE-1:0] lineLoc;
    wire [LEN_INDEX-1:0] index;
    wire [LEN_TAG-1:0] tag;
    
    reg [LEN_TAG-1:0] tag_M2;
    reg [LEN_INDEX-1:0] index_M2;
    reg [LEN_LINE-1:0] lineLoc_M2;
    // No Cache Should be Execute in M2
    typedef struct packed {
        logic [31:0]    waddr;
        logic [2:0]     wsize;
        logic [3:0]     wstrb;
        logic [31:0]    wdata; // note: data should place at correct place. (like axi)
    } store_buffer_entry;
    parameter SIZE_STORE_BUFFER = 4;
    typedef struct packed {
        logic [$clog2(SIZE_STORE_BUFFER)-1:0] ptr_begin;
        logic [$clog2(SIZE_STORE_BUFFER)-1:0] ptr_end;
        logic axi_busy;
    } store_buffer_control;

    reg  no_cache_M2;
    reg [3:0] data_sram_wen_M2;
    reg cpu_data_en_M2;
    reg cpu_data_wr_M2;
    reg [31:0] cpu_data_wdata_M2;
    reg [1:0] cpu_data_size_M2;
    reg [31:0] cpu_data_addr_M2;

    reg no_cache_M3;
    reg [LEN_LINE-1:0] lineLoc_M3;
    reg [LEN_INDEX-1:0] index_M3;
    reg [LEN_TAG-1:0] tag_M3;
    reg [3:0] data_sram_wen_M3;
    reg cpu_data_en_M3;
    reg cpu_data_wr_M3;
    reg [31:0] cpu_data_wdata_M3;
    reg [1:0] cpu_data_size_M3;
    reg [31:0] cpu_data_addr_M3;


    assign lineLoc = cpu_data_addr[LEN_LINE - 1 : 0];
    assign index = cpu_data_addr[LEN_INDEX + LEN_LINE - 1 : LEN_LINE];
    assign tag = cpu_data_addr[31 : LEN_INDEX + LEN_LINE];

    
    wire [LEN_TAG-1:0]   tag_compare;
    reg  [31:0]          NoCache_rdata;
    //Cache line something
    reg [1:0]                 c_valid_M2;
    reg [1:0]                 c_dirty_M2; // 是否修改过
    reg [1:0]                 c_lru_M2   ; //* recently used
    reg [LEN_TAG-1:0]         c_tag_M2  [1:0];
    reg [DATA_WIDTH-1:0]      c_block_M2[1:0];
    wire [1:0]                c_way;

    reg [1:0]                 c_valid_M3;
    reg [1:0]                 c_dirty_M3; // 是否修改过
    reg [1:0]                 c_lru_M3   ; //* recently used
    reg [LEN_TAG-1:0]         c_tag_M3  [1:0];
    reg                       tway_M3;

    //判断是否命中
    wire hit, miss;
    reg cpu_data_ok;
    reg FristReq;
    //FSM
    parameter IDLE = 3'b000, CACHE_REPLACE = 3'b001, CACHE_WRITEBACK = 3'b011, NOCACHE = 3'b010, SAVE_RES=3'b100;
    reg [2:0] pre_state;
    reg [2:0] state;
    wire isIDLE;
    assign isIDLE = state==IDLE;

    // judge the right time
    assign index_Res = isIDLE ? index_M2 : index_M3;
    assign tag_compare = isIDLE ? tag_M2 : tag_M3;
    assign no_cache_res = isIDLE ? no_cache_M2 : no_cache_M3;
    assign data_wr_en = isIDLE ? cpu_data_wr_M2: cpu_data_wr_M3;
    assign data_en = isIDLE ? cpu_data_en_M2 : cpu_data_en_M3;
    // hit and miss
    assign c_way[0] = c_valid_M2[0] & (c_tag_M2[0] == tag_M2);
    assign c_way[1] = c_valid_M2[1] & (c_tag_M2[1] == tag_M2);

    assign hit = |c_way & isIDLE & ~no_cache_M2;
    assign miss = ~hit;

    // load and store
    wire load, store;
    assign store = data_wr_en;
    assign load = data_en & ~store;

    //* cache当前位置是否dirty
    wire dirty, clean;
    assign dirty = c_dirty_M2[c_lru_M2[1]];
    assign clean = ~dirty;

    // axi cnt
    logic [LEN_LINE-1:2] axi_cnt;
    logic [LEN_LINE:2] cache_buff_cnt;
    reg buff_last;

    store_buffer_entry store_buffer[SIZE_STORE_BUFFER-1:0];
    store_buffer_control store_buffer_ctrl;
    wire store_buffer_has_next = store_buffer_ctrl.ptr_begin != store_buffer_ctrl.ptr_end;
    wire store_buffer_busy = store_buffer_has_next | store_buffer_ctrl.axi_busy;
    wire store_buffer_full = (store_buffer_ctrl.ptr_end + 1'd1) == store_buffer_ctrl.ptr_begin;
    
    assign d_stall = (~hit  & ~cpu_data_ok & data_en) | store_buffer_full ;
    //  & ~(i_stall & isIDLE)
    wire cache_en1 = ~(d_stall | alu_stallE);
    wire cache_en = ~cpu_data_ok & data_en;

    reg [31:0] axi_data_rdata;
    assign cpu_data_rdata   = pre_state != IDLE ? axi_data_rdata : c_block_M2[c_way[1]];


    logic [1:0] wena_tag_ram_way;
    logic [3:0] wena_data_bank_way [NR_WAYS-1:0]; // 4 bytes
    logic [31:0] wdata_buffer[NR_WORDS -1 :0];
    
    // hit and write
    wire [1:0] wena_tag_hitway;
    assign  wena_tag_hitway = hit & store ?
            {{c_way[1]}, {~c_way[1]}} : wena_tag_ram_way; // 4 bytes
    wire [3:0] wena_data_hitway [NR_WAYS-1:0];
    assign  wena_data_hitway = hit & store ?
            {{data_sram_wen_M2 & {4{c_way[1]}}}, {data_sram_wen_M2 & {4{~c_way[1]}}}} : wena_data_bank_way; // 4 bytes
    // write back part
    wire [LEN_PER_WAY-1 : 2] writeback_raddr = {index_M3,cache_buff_cnt[LEN_LINE-1:2]};

    // first : write data come from ram
    // second : come from cpu
    wire [31:0] write_cache_data = d_rdata & ~{{8{data_sram_wen_M3[3]}}, {8{data_sram_wen_M3[2]}}, {8{data_sram_wen_M3[1]}}, {8{data_sram_wen_M3[0]}}} | 
                              cpu_data_wdata_M3 & {{8{data_sram_wen_M3[3]}}, {8{data_sram_wen_M3[2]}}, {8{data_sram_wen_M3[1]}}, {8{data_sram_wen_M3[0]}}};
    
    wire [31:0] data_write = (store & hit) ? cpu_data_wdata_M2 : 
                                (axi_cnt == lineLoc_M3[LEN_LINE-1:2] & store)?  write_cache_data:  d_rdata;
                                
    
    wire isNO_CACHE = state==NOCACHE;
    wire isCACHE_REPLACE = state==CACHE_REPLACE;
    wire isCACHE_WRITEBACK = state==CACHE_WRITEBACK;
    wire isSAVERES = state==SAVE_RES;

    // axi d_bready
    assign d_bready = 1'b1;


    always @(posedge clk) begin
        if(rst) begin
            index_M2 <= 0;
            lineLoc_M2 <= 0;
            tag_M2 <= 0;
            cpu_data_wr_M2 <= 0;
            cpu_data_en_M2 <= 0;
            //Nocache Process
            store_buffer <= '{default: '0};
            // clear store buffer
            store_buffer_ctrl <= 0;
            no_cache_M2 <= 0;
            data_sram_wen_M2 <= 0;
            cpu_data_wdata_M2 <= 0;
            cpu_data_size_M2 <= 0;
            cpu_data_addr_M2 <= 0;
            
            c_valid_M2 <= 2'b00;
            c_dirty_M2 <= 2'b00;
            c_lru_M2 <= 2'b00;
        end
        else if(cache_en1)begin
            //Nocache Process
            if (no_cache & cpu_data_wr) begin
                store_buffer[store_buffer_ctrl.ptr_end] <= '{
                    waddr: cpu_data_addr,
                    wsize: {1'b0,cpu_data_size},
                    wstrb: data_sram_wen,
                    wdata: cpu_data_wdata
                };
                store_buffer_ctrl.ptr_end <= store_buffer_ctrl.ptr_end + 1;

                index_M2 <= 0;
                lineLoc_M2 <= 0;
                tag_M2 <= 0;
                cpu_data_wr_M2 <= 0;
                cpu_data_en_M2 <= 0;
                //Nocache Process
                // clear store buffer
                no_cache_M2 <= 0;
                data_sram_wen_M2 <= 0;
                cpu_data_wdata_M2 <= 0;
                cpu_data_size_M2 <= 0;
                cpu_data_addr_M2 <= 32'hbfc;
                
                c_valid_M2 <= 2'b00;
                c_dirty_M2 <= 2'b00;
                c_lru_M2 <= 2'b00;
            end
            else begin
                lineLoc_M2 <= lineLoc;
                index_M2 <= index;
                tag_M2 <= tag;
                cpu_data_wr_M2 <= cpu_data_wr;
                cpu_data_en_M2 <= cpu_data_en;
                no_cache_M2 <= no_cache;
                data_sram_wen_M2 <= data_sram_wen;
                cpu_data_wdata_M2 <= cpu_data_wdata;
                cpu_data_size_M2 <= cpu_data_size;
                cpu_data_addr_M2 <= cpu_data_addr;
                c_dirty_M2[0] <= cache_dirty[index][0];
                c_dirty_M2[1] <= cache_dirty[index][1];
                c_valid_M2[0] <= cache_valid[index][0];
                c_valid_M2[1] <= cache_valid[index][1];
                c_lru_M2   [0] <= cache_lru   [index][0];
                c_lru_M2   [1] <= cache_lru   [index][1];
            end
            
        end
    end


    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            pre_state <= IDLE;
            index_M3 <= 0;
            lineLoc_M3 <= 0;
            tag_M3 <= 0;
            tway_M3 <= 0;
            no_cache_M3 <= 0;
            cpu_data_en_M3 <= 0;
            cpu_data_wr_M3 <= 0;
            cpu_data_ok <= 0;
            cpu_data_wdata_M3 <= 0;
            cpu_data_size_M3 <= 0;
            cpu_data_addr_M3 <= 0;
            data_sram_wen_M3 <= 0;
            c_tag_M3 <= '{default: '0};
            c_dirty_M3 <=  '{default: '0};
            c_lru_M3 <=  '{default: '0};
            c_valid_M3 <= '{default: '0};
            cache_dirty <= '{default: '0};
            cache_lru <= '{default: '0};
            cache_valid <= '{default: '0};
            wdata_buffer <= '{default: '0};
            wena_data_bank_way <= '{default: '0};
            wena_tag_ram_way <= '{default: '0};
            axi_data_rdata <= 0;
            axi_cnt <= 0;
            cache_buff_cnt <=0;
            buff_last <= 0;
            // clear axi
            d_arlen <= 0;
            d_arsize <= 0;
            d_arvalid <= 0;
            d_rready <= 0;
            d_awaddr <= 0;
            d_awlen <= 0;
            d_awsize <= 0;
            d_awvalid <= 0;
            d_wdata <= 0;
            d_wstrb <= 0;
            d_wlast <= 0;
            d_wvalid <= 0;
            FristReq <=0;
        end
        else begin
            if (store_buffer_busy) begin
                if (store_buffer_ctrl.axi_busy) begin // To implement SC memory ordering, if store buffer busy, axi is unseable.
                    if (d_awvalid & d_awready) begin
                        d_awvalid <= 0;
                        d_wvalid <= 1'b1;
                        d_wlast <= 1'b1;
                    end
                    if (d_wvalid & d_wready) begin
                        d_wvalid <= 0;
                        d_wlast <= 0;
                    end
                    if (d_bvalid & d_bready) begin
                        store_buffer_ctrl.axi_busy <= 1'b0;
                    end
                end
                else begin
                    d_awaddr <= store_buffer[store_buffer_ctrl.ptr_begin].waddr;
                    d_awlen <= 0;
                    d_awsize <= store_buffer[store_buffer_ctrl.ptr_begin].wsize;
                    d_awvalid <= 1'b1;
                    d_wdata <= store_buffer[store_buffer_ctrl.ptr_begin].wdata;
                    d_wstrb <= store_buffer[store_buffer_ctrl.ptr_begin].wstrb;
                    
                    store_buffer_ctrl.ptr_begin <= store_buffer_ctrl.ptr_begin + 1;
                    store_buffer_ctrl.axi_busy <= 1'b1;
                end
            end

            if(cache_en)begin          
                pre_state <= state;  
                case(state)
                // 按照状态机编写
                    IDLE: begin 
                        c_tag_M3 <= c_tag_M2;
                        c_dirty_M3 <=  c_dirty_M2;
                        c_lru_M3 <=  c_lru_M2;
                        c_valid_M3 <= c_valid_M2;
                        index_M3 <= index_M2;
                        lineLoc_M3 <= lineLoc_M2;
                        no_cache_M3 <= no_cache_M2;
                        tag_M3 <= tag_M2;
                        cpu_data_en_M3 <= cpu_data_en_M2;
                        cpu_data_wr_M3 <= cpu_data_wr_M2;
                        cpu_data_wdata_M3 <= cpu_data_wdata_M2;
                        cpu_data_size_M3 <= cpu_data_size_M2;
                        cpu_data_addr_M3 <= cpu_data_addr_M2;
                        data_sram_wen_M3 <= data_sram_wen_M2;
                        if (no_cache_M2) begin
                            d_araddr <= cpu_data_addr_M2;
                            d_arlen  <= 0;
                            d_arsize <= 3'd2;
                            FristReq <= 0;
                            state <= NOCACHE;
                        end
                        else if (hit) begin
                            state <= IDLE;
                            if(cpu_data_wr_M2) begin
                                cache_dirty[index_M2][c_way[1]] <= 1'b1;
                            end
                            cache_lru[index_M2][c_way[1]] <=1'b0;
                            cache_lru[index_M2][~c_way[1]] <=1'b1;
                        end
                        else begin
                            if (miss & dirty)begin
                                state <= CACHE_WRITEBACK;
                                d_awaddr <= {c_tag_M2[c_lru_M2[1]], index_M2,{LEN_LINE{1'b0}}};
                                d_awlen <= NR_WORDS - 1;
                                wena_data_bank_way <= '{default: '0};
                                wena_tag_ram_way <= '{default: '0}; 
                                d_awsize <= 3'd2;
                                axi_cnt <= 1;
                            end
                            else if (miss & clean)begin
                                state <= CACHE_REPLACE;
                                d_araddr <= {tag_M2, index_M2,{LEN_LINE{1'b0}}};
                                d_arlen <= NR_WORDS - 1;
                                d_arsize <= 3'd2;
                                d_arvalid <= 1'b1;
                                wena_data_bank_way[c_lru_M2[1]] <= 4'hf;// write to instram
                                wena_data_bank_way[~c_lru_M2[1]] <= 4'h0;// write to instram
                                wena_tag_ram_way <= {c_lru_M2[1],~c_lru_M2[1]}; //write to tag
                                axi_cnt <= 0;
                            end
                            if(cpu_data_wr_M2) begin
                                cache_dirty[index_M2][c_lru_M2[1]] <= 1'b1;
                            end
                            tway_M3 <= c_lru_M2[1];
                            cache_lru[index_M2][c_lru_M2[1]] <=1'b0;
                            cache_lru[index_M2][~c_lru_M2[1]] <=1'b1;
                            cache_valid[index_M2][c_lru_M2[1]] <= 1'b1;
                            cache_buff_cnt <=0;
                            buff_last <= 0;
                        end
                    end
                    CACHE_WRITEBACK: begin              
                        if (!store_buffer_busy) begin
                            d_wstrb <= 4'b1111; // 写哪几位
                            if (cache_buff_cnt != NR_WORDS) begin
                                // not first time, todo addr
                                cache_buff_cnt <= cache_buff_cnt + 1;
                            end
                            else begin
                                buff_last <= 1;
                            end
                            if (cache_buff_cnt != 0 &  ~buff_last) begin
                                // write to buffer
                                wdata_buffer[cache_buff_cnt-1] <= c_block_M2[tway_M3];
                            end
                            if (cache_buff_cnt == 1) begin
                                // write to buffer
                                d_wdata <= c_block_M2[tway_M3];
                                d_awvalid <= 1'b1;
                            end
                        end
                        
                        if (d_awvalid & d_awready) begin
                            // First Time
                            d_awvalid <= 1'b0;
                            d_wvalid <=1'b1;
                            d_wlast <=1'b0;
                        end
                        if (d_wvalid & d_wready) begin
                            // write one word every wready 
                            if (d_wlast) begin
                                d_wvalid <= 1'b0;
                                d_wlast <= 1'b0;
                            end
                            else begin
                                d_wdata <=  wdata_buffer[axi_cnt];
                                axi_cnt <= axi_cnt + 1;
                                if (axi_cnt  == NR_WORDS - 1) begin
                                    d_wlast <= 1'b1;
                                end
                            end
                        end
                        if (d_bvalid & d_bready) begin
                            // write to cache 
                            d_araddr <= {tag_M3, index_M3,{LEN_LINE{1'b0}}};
                            d_arlen <= NR_WORDS - 1;
                            d_arsize <= 3'd2;
                            d_arvalid <= 1'b1;
                            d_wlast <= 1'b0;
                            buff_last <= 0;
                            axi_cnt <= 0 ;
                            wena_data_bank_way[tway_M3] <= 4'hf;// write to instram
                            wena_data_bank_way[~tway_M3] <= 4'h0;// write to instram
                            wena_tag_ram_way[tway_M3] <= 1;
                            cache_dirty[index_M3][tway_M3] <= 0;
                            state <= CACHE_REPLACE;
                        end
                    end
                    CACHE_REPLACE: begin
                        state <= CACHE_REPLACE;
                        if (d_arvalid) begin
                            if (d_arready) begin
                                d_arvalid <= 0;
                                d_rready <= 1'b1;
                            end
                        end
                        else begin
                            if (d_rvalid & d_rready) begin
                                if (!d_rlast) begin
                                    axi_cnt <= axi_cnt + 1;
                                    if(axi_cnt == lineLoc_M3[LEN_LINE-1:2]) 
                                        axi_data_rdata <= d_rdata;
                                end
                                else begin
                                    d_rready <= 0;
                                    wena_data_bank_way[tway_M3] <= 0;
                                    wena_tag_ram_way[tway_M3] <= 0;
                                    if(axi_cnt == lineLoc_M3[LEN_LINE-1:2]) 
                                        axi_data_rdata <= d_rdata;
                                end
                                if(store) cache_dirty[index_M3][tway_M3] <= 1;
                            end
                            else if (!d_rready) begin // wait the final data write to bram.
                                state <= IDLE;
                                cpu_data_ok <= 1;
                            end
                        end
                    end
                    NOCACHE: begin
                        if (!store_buffer_busy) begin
                            if(~FristReq) begin
                                d_arvalid <= 1'b1;
                                FristReq <=1;
                            end
                            if (d_arvalid & d_arready) begin
                                d_arvalid <= 0;
                                d_rready <= 1'b1;
                            end
                            else if (d_rvalid & d_rready) begin
                                d_rready <= 1'b0;
                                axi_data_rdata <= d_rdata;
                            end
                            else if (~d_rready & FristReq & ~d_arvalid)begin
                                cpu_data_ok <=1;
                                state <= IDLE;
                            end
                        end
                    end
                endcase
            end
            else if (cache_en1)begin
                no_cache_M3 <= 0;
                cpu_data_ok <= 0;
                FristReq <= 0;
                pre_state <= state;
            end
        end
        
    end

    
    genvar i;
    generate
        for (i=0;i<2;i++)begin
            tag_ram #(.LEN_DATA(LEN_TAG),.LEN_ADDR(LEN_INDEX)) d_tag
            (
            .clka   (clk),
            .clkb   (clk),
            .ena    (1'b1),
            .enb    (cache_en1 | isCACHE_WRITEBACK),
            .addra  (index_Res),
            .dina   (tag_compare),
            .wea    (wena_tag_hitway[i]),
            .addrb  (index),
            .doutb  (c_tag_M2[i])
            );
            cache_block_ram #(.LEN_DATA(32),.LEN_ADDR(LEN_PER_WAY-2))d_data
            (
            .clka   (clk),
            .clkb   (clk),
            .ena    (1'b1),
            .enb    (cache_en1 | isCACHE_WRITEBACK),
            .addra  ({index_Res, (hit & store ? lineLoc_M2[LEN_LINE-1:2] : axi_cnt)}),
            .dina   (data_write),
            .wea    (wena_data_hitway[i]),
            .addrb  (isCACHE_WRITEBACK ? writeback_raddr: {index,lineLoc[LEN_LINE-1:2]}),
            .doutb  (c_block_M2[i])
            );
        end
    endgenerate
endmodule