`include "defines2.vh"

module mem_control(
    input wire        clk, rst, 
    input wire [31:0] instr1M, instr2M,
    input wire [31:0] address1M, address2M,  //save and load 
    input wire mem_selM, Blank_SL, stallM2, flushM2,

    input wire [31:0] data_wdata1M, data_wdata2M, //要写的数据
    input wire [31:0] rt_valueM2,  //rt寄存器的值
    output reg [31:0] writedataM, writedataW,//真正写数据
    output reg [3:0] mem_write_selectM, mem_write_selectW, //选择写哪一位

    input wire [31:0] mem_rdataM2, //内存读出
    output reg [31:0] data_rdataM2,  // 实际读出
    output wire [31:0] data_srcM,
    output wire [31:0] data_addrM,
    output wire [1:0]   data_size,
    output reg addr_error_sw1, addr_error_lw1, addr_error_sw2, addr_error_lw2
);
    

    wire mem_selM2;
    wire [5:0] op_codeM;
    wire [5:0] op_codeM2;
    wire [31:0] addressM;
    wire [31:0] addressM2;

    wire addr_W0M, addr_B2M, addr_B1M, addr_B3M;
    wire addr_W0M2, addr_B2M2, addr_B1M2, addr_B3M2;

    flopstrc #(7) flopMemSignM2(.clk(clk),.rst(rst),.stall(stallM2),.flush(flushM2),
            .in({op_codeM, mem_selM}),.out({op_codeM2, mem_selM2}));
    flopstrc #(32) flopAddressM2(.clk(clk),.rst(rst),.stall(stallM2),.flush(flushM2),.in(addressM),.out(addressM2));

    assign op_codeM = mem_selM ? instr1M[31:26] : instr2M[31:26];
    assign addressM =  mem_selM ? address1M : address2M;
    assign data_srcM = mem_selM ? data_wdata1M: data_wdata2M;
    assign data_addrM = addressM ; 
    // Load and save sel
    assign addr_W0M = (addressM[1:0] == 2'b00);
    assign addr_B2M = (addressM[1:0] == 2'b10);
    assign addr_B1M = (addressM[1:0] == 2'b01);
    assign addr_B3M = (addressM[1:0] == 2'b11);
    // Load  sel
    assign addr_W0M2 = (addressM2[1:0] == 2'b00);
    assign addr_B2M2 = (addressM2[1:0] == 2'b10);
    assign addr_B1M2 = (addressM2[1:0] == 2'b01);
    assign addr_B3M2 = (addressM2[1:0] == 2'b11);

    always@(*)begin
        writedataM = 32'b0;
        addr_error_sw1 = 1'b0;
        addr_error_lw1 = 1'b0;
        addr_error_sw2 = 1'b0;
        addr_error_lw2 = 1'b0;
        case(op_codeM)
            `SW: begin
                data_size = 2'd2;
                mem_write_selectM = {4{addr_W0M}} & 4'b1111;
                writedataM = data_srcM;
                addr_error_sw1 = mem_selM  & ~addr_W0M;
                addr_error_sw2 = ~mem_selM  & ~addr_W0M;
            end
            `SWL: begin
                data_size = 2'd2;
                mem_write_selectM = ~((4'b1110) << addressM[1:0]); // ~ 按位取反
                writedataM = {32{addr_B3M}} & (data_srcM      ) |
                            {32{addr_B2M}} & (data_srcM >> 8 ) |
                            {32{addr_B1M}} & (data_srcM >> 16) |
                            {32{addr_W0M}} & (data_srcM >> 24) ;
            end
            `SWR: begin
                data_size = 2'd2;
                mem_write_selectM = (4'b1111) << addressM[1:0]; // ~ 按位取反
                writedataM = {32{addr_B3M}} & (data_srcM << 24) |
                            {32{addr_B2M}} & (data_srcM << 16) |
                            {32{addr_B1M}} & (data_srcM << 8 ) |
                            {32{addr_W0M}} & (data_srcM      ) ;
            end
            `SC: begin
                data_size = 2'd2;
                mem_write_selectM = {4{addr_W0M}} & 4'b1111;
                writedataM = data_srcM;
                addr_error_sw1 = mem_selM  & ~addr_W0M;
                addr_error_sw2 = ~mem_selM  & ~addr_W0M;
            end
            `SH: begin
                data_size = 2'd1;
                mem_write_selectM = {4{addr_B2M}} & 4'b1100 |
                                    {4{addr_W0M}} & 4'b0011 ;
                writedataM = {data_srcM[15:0],data_srcM[15:0]};
                addr_error_sw1 = mem_selM  & ~(addr_W0M | addr_B2M);
                addr_error_sw2 = ~mem_selM  & ~(addr_W0M | addr_B2M);
            end
            `SB: begin
                data_size = 2'd0;
                mem_write_selectM = {4{addr_B3M}} & 4'b1000 |
                                {4{addr_B2M}} & 4'b0100 |
                                {4{addr_B1M}} & 4'b0010 |
                                {4{addr_W0M}} & 4'b0001 ;
                writedataM = {data_srcM[7:0],data_srcM[7:0],data_srcM[7:0],data_srcM[7:0]};
            end
            `LW: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd2;
                addr_error_lw1 = mem_selM & ~addr_W0M;
                addr_error_lw2 = ~mem_selM  & ~addr_W0M;
            end
            `LL: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd2;
                addr_error_lw1 = mem_selM & ~addr_W0M;
                addr_error_lw2 = ~mem_selM  & ~addr_W0M;
            end
            `LH: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd1;
                addr_error_lw1 = mem_selM & ~(addr_W0M | addr_B2M);
                addr_error_lw2 = ~mem_selM  & ~(addr_W0M | addr_B2M);
            end
            `LHU: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd1;
                addr_error_lw1 = mem_selM & ~(addr_W0M | addr_B2M);
                addr_error_lw2 = ~mem_selM  & ~(addr_W0M | addr_B2M);
            end
            `LB: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd0;
            end
            `LBU: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd0;
            end
            `LWL: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd2;
            end
            `LWR: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd2;
            end
            default:begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd0;
            end
        endcase
    end
    always@(*)begin
        case(op_codeM2)
            `LW: begin
                data_rdataM2 = mem_rdataM2;
            end
            `LL: begin
                data_rdataM2 = mem_rdataM2;
            end
            `LH: begin
                data_rdataM2 = {32{addr_B2M2}} & {{16{mem_rdataM2[31]}},mem_rdataM2[31:16]} |
                                {32{addr_W0M2}} & {{16{mem_rdataM2[15]}},mem_rdataM2[15: 0]} ;
            end
            `LHU: begin
                data_rdataM2 = {32{addr_B2M2}} & {{16{1'b0}},mem_rdataM2[31:16]} |
                                {32{addr_W0M2}} & {{16{1'b0}},mem_rdataM2[15: 0]} ;
            end
            `LB: begin
                data_rdataM2 = {32{addr_B3M2}} & {{24{mem_rdataM2[31]}},mem_rdataM2[31:24]} |
                                {32{addr_B2M2}} & {{24{mem_rdataM2[23]}},mem_rdataM2[23:16]} |
                                {32{addr_B1M2}} & {{24{mem_rdataM2[15]}},mem_rdataM2[15: 8]} |
                                {32{addr_W0M2}} & {{24{mem_rdataM2[ 7]}},mem_rdataM2[7 : 0]} ;
            end
            `LBU: begin
                data_rdataM2 = {32{addr_B3M2}} & {{24{1'b0}},mem_rdataM2[31:24]} |
                                {32{addr_B2M2}} & {{24{1'b0}},mem_rdataM2[23:16]} |
                                {32{addr_B1M2}} & {{24{1'b0}},mem_rdataM2[15: 8]} |
                                {32{addr_W0M2}} & {{24{1'b0}},mem_rdataM2[7 : 0]} ;
            end
            `LWL: begin
                data_rdataM2 = {32{addr_B3M2}} & ((mem_rdataM2      ) | (rt_valueM2 & 32'h0       )) |
                                {32{addr_B2M2}} & ((mem_rdataM2 << 8 ) | (rt_valueM2 & 32'h000000ff)) |
                                {32{addr_B1M2}} & ((mem_rdataM2 << 16) | (rt_valueM2 & 32'h0000ffff)) |
                                {32{addr_W0M2}} & ((mem_rdataM2 << 24) | (rt_valueM2 & 32'h00ffffff)) ;
            end
            `LWR: begin
                data_rdataM2 = {32{addr_B3M2}} & ((mem_rdataM2 >> 24) | (rt_valueM2 & 32'hffffff00)) |
                                {32{addr_B2M2}} & ((mem_rdataM2 >> 16) | (rt_valueM2 & 32'hffff0000)) |
                                {32{addr_B1M2}} & ((mem_rdataM2 >> 8 ) | (rt_valueM2 & 32'hff000000)) |
                                {32{addr_W0M2}} & ((mem_rdataM2      ) | (rt_valueM2 & 32'h0       )) ;
            end
            default:begin
                data_rdataM2 = 32'b0 ;
            end
        endcase
    end
endmodule
