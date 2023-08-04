module i_cache #(
    parameter LEN_LINE = 6,  // 32 Bytes
    parameter LEN_INDEX = 7, // 128 lines
    parameter NR_WAYS = 2
) (
    input wire clk, rst, no_cache, icache_Ctl,
    output wire i_stall,
    //mips core input
    input  [31:0] cpu_inst_addr    ,
    input         cpu_inst_en      ,
    //mips core output
    output [31:0] cpu_inst_rdata   ,
    //I CACHE
    output reg [31:0] i_araddr,
    output reg [7:0] i_arlen,
    output reg [2:0] i_arsize,
    output reg       i_arvalid,
    input wire        i_arready,

    input wire [31:0] i_rdata,
    input wire        i_rlast,
    input wire        i_rvalid,
    output reg       i_rready
);
    // defines
    localparam LEN_PER_WAY = LEN_LINE + LEN_INDEX;
    localparam LEN_TAG = 32 - LEN_LINE - LEN_INDEX;
    localparam LEN_BRAM_ADDR = LEN_LINE - 3 + LEN_INDEX;
    localparam CACHE_DEEPTH = 1 << LEN_INDEX;
    localparam NR_WORDS = 1 << (LEN_LINE - 2);

    
    (*ram_style="block"*) reg [1:0]               cache_valid [CACHE_DEEPTH - 1 : 0];
    (*ram_style="block"*) reg [1:0]               cache_lru    [CACHE_DEEPTH - 1 : 0]; 

    
    wire [LEN_LINE-1:0] lineLoc;
    wire [LEN_INDEX-1:0] index;
    wire [LEN_TAG-1:0] tag;

    reg [LEN_LINE-1:0] lineLoc_IF2;
    reg [LEN_INDEX-1:0] index_IF2;
    reg [LEN_TAG-1:0] tag_IF2;
    reg  no_cache_IF2;
    reg  cpu_inst_en_IF2;

    reg [LEN_LINE-1:0] lineLoc_IF3;
    reg [LEN_INDEX-1:0] index_IF3;
    reg [LEN_TAG-1:0] tag_IF3;
    reg tway_IF3;
    reg  cpu_inst_en_IF3;
    
    logic [1:0] wena_tag_ram_way;
    logic [3:0] wena_data_bank_way [NR_WAYS-1:0];
    
    assign lineLoc = cpu_inst_addr[LEN_LINE - 1 : 0];
    assign index = cpu_inst_addr[LEN_INDEX + LEN_LINE - 1 : LEN_LINE];
    assign tag = cpu_inst_addr[31 : LEN_INDEX + LEN_LINE];

    //  Select
    wire                 inst_en;
    //  IF2
    reg  [1:0]           c_valid_IF2;
    reg  [1:0]           c_lru_IF2; //* recently used
    reg [LEN_TAG-1:0]   c_tag_IF2  [1:0];
    reg [31:0]          c_block_IF2[1:0];
    wire [1:0]           c_way;
	
    reg[1:0]            c_valid_IF3;
    reg[1:0]            c_lru_IF3 ; //* recently used
    reg [LEN_TAG-1:0]   c_tag_IF3  [1:0];

    //FSM
    parameter IDLE = 2'b00, CACHE_REPLACE = 2'b01, NOCACHE =2'b10;
    reg [1:0] pre_state;
    reg [1:0] state;
    wire isIDLE, isReplace;
    assign isIDLE = state==IDLE;
    assign isReplace = state==CACHE_REPLACE;
    
    // hit miss and way
    wire hit, miss;
    reg  cpu_instr_ok;
    // Time Control 
    assign inst_en = isIDLE ? cpu_inst_en_IF2 : cpu_inst_en_IF3;

    // hit Control
    assign hit = |c_way & isIDLE;  //* cache line
    assign miss = ~hit;

    assign c_way[0] = c_valid_IF2[0] & ((c_tag_IF2[0] == tag_IF2));
    assign c_way[1] = c_valid_IF2[1] & ((c_tag_IF2[1] == tag_IF2));
    assign i_stall = (~isIDLE | ~hit | no_cache_IF2 ) & inst_en & ~cpu_instr_ok;
    wire cache_en = ~icache_Ctl | i_stall; 
    //output to mips core
    // first stage is not stall, and the second judge whether to stall
    reg [31:0] axi_inst_rdata;
    assign cpu_inst_rdata   = pre_state != IDLE ? axi_inst_rdata : c_block_IF2[c_way[1]];

    // axi cnt
    logic [LEN_LINE-1:2] axi_cnt;

    always @(posedge clk) begin
        if(rst) begin
            index_IF2 <= 0;
            lineLoc_IF2 <= 0;
            tag_IF2 <= 0;
            //Nocache Process
            cpu_inst_en_IF2 <= 0;
            no_cache_IF2 <= 0;
            // valid and lru is not be updated 
            c_valid_IF2 <= 0;
            c_lru_IF2 <= 0;
        end
        else if(cache_en)begin
            lineLoc_IF2 <= lineLoc;
            index_IF2 <= index;
            tag_IF2 <= tag;
            cpu_inst_en_IF2 <= cpu_inst_en;
            no_cache_IF2 <= no_cache;
            c_valid_IF2 <= cache_valid[index];
            c_lru_IF2    <= cache_lru[index];
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            cpu_instr_ok <= 0;
            state <= IDLE;
            cpu_inst_en_IF3 <= 0;
            pre_state <= IDLE;
            index_IF3 <= 0;
            lineLoc_IF3 <= 0;
            tag_IF3 <= 0;
            axi_inst_rdata <= 0;
            // clear status
            wena_data_bank_way <= '{default: '0};
            wena_tag_ram_way <= '{default: '0};
            cache_valid <= '{default: '0};
            cache_lru <= '{default: '0};
            // Valid and lru should be floped
            c_tag_IF3 <= '{default: '0};
            c_valid_IF3 <= '{default: '0};
            c_lru_IF3 <= '{default: '0};
            // clear axi output
            i_araddr <= 0;
            i_arlen <= 0;
            i_arsize <= 0;
            i_arvalid <= 0;
            i_rready <= 0;
            // clear axi status
            axi_cnt <= 0;
        end
        else if (inst_en & cache_en)begin
            pre_state <= state;
            case(state)
                IDLE: begin
                    cpu_instr_ok <= 1'b0;
                    cpu_inst_en_IF3 <= cpu_inst_en_IF2;
                    index_IF3 <= index_IF2;
                    lineLoc_IF3 <= lineLoc_IF2;
                    tag_IF3 <= tag_IF2;
                    // Valid and lru should be floped
                    c_valid_IF3 <= c_valid_IF2;
                    c_lru_IF3 <= c_lru_IF2;
                    c_tag_IF3 <= c_tag_IF2;
                    if (no_cache_IF2) begin
                        i_araddr <= {tag_IF2, index_IF2, lineLoc_IF2};
                        i_arlen  <= 0;
                        i_arsize <= 3'd2;
                        i_arvalid <= 1'b1;
                        state <= NOCACHE;
                    end
                    else if (!hit) begin
                        tway_IF3 <= c_lru_IF2[1];
                        i_araddr <= {tag_IF2, index_IF2,{LEN_LINE{1'b0}}};
                        i_arlen <= NR_WORDS - 1;
                        i_arsize <= 3'd2; //4 bytes
                        i_arvalid <= 1'b1;  //read addr is valid
                        // Write ena
                        wena_data_bank_way[c_lru_IF2[1]] <= 4'hf;// write to instram
                        wena_data_bank_way[~c_lru_IF2[1]] <= 4'h0;
                        wena_tag_ram_way <= {c_lru_IF2[1],~c_lru_IF2[1]}; //write to tag
                        cache_valid[index_IF2][c_lru_IF2[1]] <= 1'b1;
                        cache_lru[index_IF2][c_lru_IF2[1]] <=1'b0;
                        cache_lru[index_IF2][~c_lru_IF2[1]] <=1'b1;
                        axi_cnt <= 0;
                        state <= CACHE_REPLACE;
                    end
                    else begin
                        // Update LRU when icache hit
                        // Note: If NR_WAYS > 2, we should implement pseudo-LRU or LFSR.
                        cache_lru[index_IF2][c_way[1]] <=1'b0;
                        cache_lru[index_IF2][~c_way[1]] <=1'b1;
                    end
                end
                NOCACHE: begin
                    if (i_arvalid) begin
                        if (i_arready) begin
                            i_arvalid <= 0;
                            i_rready <= 1'b1;
                        end
                    end
                    else if (i_rvalid & i_rready) begin
                        i_rready <= 1'b0;
                        axi_inst_rdata <= i_rdata;
                    end
                    else if (~i_rvalid & ~i_rready)begin
                        cpu_instr_ok <=1;
                        state <= IDLE;
                    end
                end
                CACHE_REPLACE: begin
                    if (i_arvalid) begin
                        if (i_arready) begin
                            i_arvalid <= 0;
                            i_rready <= 1'b1;
                        end
                    end
                    else begin
                        if (i_rvalid & i_rready) begin
                            if (!i_rlast) begin
                                axi_cnt <= axi_cnt + 1;
                                if(axi_cnt == lineLoc_IF3[LEN_LINE-1:2]) 
                                    axi_inst_rdata <= i_rdata;
                            end
                            else begin
                                i_rready <= 0;
                                wena_data_bank_way[tway_IF3] <= 0;
                                wena_tag_ram_way[tway_IF3] <= 0;
                                if(axi_cnt == lineLoc_IF3[LEN_LINE-1:2]) 
                                    axi_inst_rdata <= i_rdata;
                            end
                        end
                        else if (!i_rready) begin // wait the final data write to bram.
                            state <= IDLE;
                            axi_cnt <=0;
                            cpu_instr_ok <= 1'b1;
                        end
                    end
                        
                end
                // default:begin
                //     state <= IDLE;
                // end
            endcase
        end
        else if(cache_en)begin
            pre_state <= state;
            cpu_instr_ok <= 0;
        end
    end

    
    genvar i;
    generate
        for (i=0;i<2;i++)begin
            tag_ram #(.LEN_DATA(LEN_TAG),.LEN_ADDR(LEN_INDEX)) i_tag 
            (
            .clka   (clk),
            .clkb   (clk),
            .ena    (wena_tag_ram_way[i]),
            .enb    (cache_en),
            .addra  (index_IF3),
            .dina   (tag_IF3),
            .wea    (wena_tag_ram_way[i]),
            .addrb  (index),
            .doutb  (c_tag_IF2[i])
            );
            cache_block_ram #(.LEN_DATA(32),.LEN_ADDR(LEN_PER_WAY-2)) i_data
            (
            .clka   (clk),
            .clkb   (clk),
            .ena    (1'b1),
            .enb    (cache_en),
            .addra  ({index_IF3,axi_cnt[LEN_LINE-1:2]}),
            .dina   (i_rdata),
            .wea    (wena_data_bank_way[i]),
            .addrb  ({index,lineLoc[LEN_LINE-1:2]}),
            .doutb  (c_block_IF2[i])
            );
        end
    endgenerate
endmodule