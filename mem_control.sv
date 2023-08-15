`include "defines2.vh"

module mem_control(
    input wire        clk, rst, 
    input wire [31:0] instr1E, instr2E,
    input wire [31:0] address1E, address2E,  //save and load 
    input wire mem_selE, stallM, flushM,

    input wire [31:0] data_wdata1E, data_wdata2E, //要写的数据
    input wire [31:0] rt_valueM,  //rt寄存器的值
    output reg [31:0] writedataE,//真正写数据
    output reg [3:0] mem_write_selectE, //选择写哪一位

    input wire [31:0] mem_rdataM, //内存读出
    output reg [31:0] data_rdataM,  // 实际读出
    output wire [31:0] data_srcE,
    output wire [31:0] data_addrE,
    output reg [1:0]   data_size,
    output reg addr_error_sw1, addr_error_lw1, addr_error_sw2, addr_error_lw2
);
    

    wire mem_selM;
    wire [5:0] op_codeE;
    wire [5:0] op_codeM;
    wire [31:0] addressE;
    wire [31:0] addressM;

    wire addr_W0E, addr_B2E, addr_B1E, addr_B3E;
    wire addr_W0M, addr_B2M, addr_B1M, addr_B3M;

    flopstrc #(7) flopMemSignM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),
            .in({op_codeE, mem_selE}),.out({op_codeM, mem_selM}));
    flopstrc #(32) flopAddressM(.clk(clk),.rst(rst),.stall(stallM),.flush(flushM),.in(addressE),.out(addressM));

    assign op_codeE = mem_selE ? instr1E[31:26] : instr2E[31:26];
    assign addressE =  mem_selE ? address1E : address2E;
    assign data_srcE = mem_selE ? data_wdata1E: data_wdata2E;
    assign data_addrE = addressE ; 
    // Load and save sel
    assign addr_W0E = (addressE[1:0] == 2'b00);
    assign addr_B2E = (addressE[1:0] == 2'b10);
    assign addr_B1E = (addressE[1:0] == 2'b01);
    assign addr_B3E = (addressE[1:0] == 2'b11);
    // Load  sel
    assign addr_W0M = (addressM[1:0] == 2'b00);
    assign addr_B2M = (addressM[1:0] == 2'b10);
    assign addr_B1M = (addressM[1:0] == 2'b01);
    assign addr_B3M = (addressM[1:0] == 2'b11);

    always@(*)begin
        writedataE = 32'b0;
        addr_error_sw1 = 1'b0;
        addr_error_lw1 = 1'b0;
        addr_error_sw2 = 1'b0;
        addr_error_lw2 = 1'b0;
        case(op_codeE)
            `SW: begin
                data_size = 2'd2;
                mem_write_selectE = {4{addr_W0E}} & 4'b1111;
                writedataE = data_srcE;
                addr_error_sw1 = mem_selE  & ~addr_W0E;
                addr_error_sw2 = ~mem_selE  & ~addr_W0E;
            end
            `SWL: begin
                data_size = 2'd2;
                mem_write_selectE = ~((4'b1110) << addressE[1:0]); // ~ 按位取反
                writedataE = {32{addr_B3E}} & (data_srcE      ) |
                            {32{addr_B2E}} & (data_srcE >> 8 ) |
                            {32{addr_B1E}} & (data_srcE >> 16) |
                            {32{addr_W0E}} & (data_srcE >> 24) ;
            end
            `SWR: begin
                data_size = 2'd2;
                mem_write_selectE = (4'b1111) << addressE[1:0]; // ~ 按位取反
                writedataE = {32{addr_B3E}} & (data_srcE << 24) |
                            {32{addr_B2E}} & (data_srcE << 16) |
                            {32{addr_B1E}} & (data_srcE << 8 ) |
                            {32{addr_W0E}} & (data_srcE      ) ;
            end
            `SC: begin
                data_size = 2'd2;
                mem_write_selectE = {4{addr_W0E}} & 4'b1111;
                writedataE = data_srcE;
                addr_error_sw1 = mem_selE  & ~addr_W0E;
                addr_error_sw2 = ~mem_selE  & ~addr_W0E;
            end
            `SH: begin
                data_size = 2'd1;
                mem_write_selectE = {4{addr_B2E}} & 4'b1100 |
                                    {4{addr_W0E}} & 4'b0011 ;
                writedataE = {data_srcE[15:0],data_srcE[15:0]};
                addr_error_sw1 = mem_selE  & ~(addr_W0E | addr_B2E);
                addr_error_sw2 = ~mem_selE  & ~(addr_W0E | addr_B2E);
            end
            `SB: begin
                data_size = 2'd0;
                mem_write_selectE = {4{addr_B3E}} & 4'b1000 |
                                {4{addr_B2E}} & 4'b0100 |
                                {4{addr_B1E}} & 4'b0010 |
                                {4{addr_W0E}} & 4'b0001 ;
                writedataE = {data_srcE[7:0],data_srcE[7:0],data_srcE[7:0],data_srcE[7:0]};
            end
            `LW: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd2;
                addr_error_lw1 = mem_selE & ~addr_W0E;
                addr_error_lw2 = ~mem_selE  & ~addr_W0E;
            end
            `LL: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd2;
                addr_error_lw1 = mem_selE & ~addr_W0E;
                addr_error_lw2 = ~mem_selE  & ~addr_W0E;
            end
            `LH: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd1;
                addr_error_lw1 = mem_selE & ~(addr_W0E | addr_B2E);
                addr_error_lw2 = ~mem_selE  & ~(addr_W0E | addr_B2E);
            end
            `LHU: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd1;
                addr_error_lw1 = mem_selE & ~(addr_W0E | addr_B2E);
                addr_error_lw2 = ~mem_selE  & ~(addr_W0E | addr_B2E);
            end
            `LB: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd0;
            end
            `LBU: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd0;
            end
            `LWL: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd2;
            end
            `LWR: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd2;
            end
            default:begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd0;
            end
        endcase
    end
    always@(*)begin
        case(op_codeM)
            `LW: begin
                data_rdataM = mem_rdataM;
            end
            `LL: begin
                data_rdataM = mem_rdataM;
            end
            `LH: begin
                data_rdataM = {32{addr_B2M}} & {{16{mem_rdataM[31]}},mem_rdataM[31:16]} |
                                {32{addr_W0M}} & {{16{mem_rdataM[15]}},mem_rdataM[15: 0]} ;
            end
            `LHU: begin
                data_rdataM = {32{addr_B2M}} & {{16{1'b0}},mem_rdataM[31:16]} |
                                {32{addr_W0M}} & {{16{1'b0}},mem_rdataM[15: 0]} ;
            end
            `LB: begin
                data_rdataM = {32{addr_B3M}} & {{24{mem_rdataM[31]}},mem_rdataM[31:24]} |
                                {32{addr_B2M}} & {{24{mem_rdataM[23]}},mem_rdataM[23:16]} |
                                {32{addr_B1M}} & {{24{mem_rdataM[15]}},mem_rdataM[15: 8]} |
                                {32{addr_W0M}} & {{24{mem_rdataM[ 7]}},mem_rdataM[7 : 0]} ;
            end
            `LBU: begin
                data_rdataM = {32{addr_B3M}} & {{24{1'b0}},mem_rdataM[31:24]} |
                                {32{addr_B2M}} & {{24{1'b0}},mem_rdataM[23:16]} |
                                {32{addr_B1M}} & {{24{1'b0}},mem_rdataM[15: 8]} |
                                {32{addr_W0M}} & {{24{1'b0}},mem_rdataM[7 : 0]} ;
            end
            `LWL: begin
                data_rdataM = {32{addr_B3M}} & ((mem_rdataM      ) | (rt_valueM & 32'h0       )) |
                                {32{addr_B2M}} & ((mem_rdataM << 8 ) | (rt_valueM & 32'h000000ff)) |
                                {32{addr_B1M}} & ((mem_rdataM << 16) | (rt_valueM & 32'h0000ffff)) |
                                {32{addr_W0M}} & ((mem_rdataM << 24) | (rt_valueM & 32'h00ffffff)) ;
            end
            `LWR: begin
                data_rdataM = {32{addr_B3M}} & ((mem_rdataM >> 24) | (rt_valueM & 32'hffffff00)) |
                                {32{addr_B2M}} & ((mem_rdataM >> 16) | (rt_valueM & 32'hffff0000)) |
                                {32{addr_B1M}} & ((mem_rdataM >> 8 ) | (rt_valueM & 32'hff000000)) |
                                {32{addr_W0M}} & ((mem_rdataM      ) | (rt_valueM & 32'h0       )) ;
            end
            default:begin
                data_rdataM = 32'b0 ;
            end
        endcase
    end
endmodule
