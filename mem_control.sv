`include "defines2.vh"
`timescale 1ns / 1ps

module mem_control(
    input wire [31:0] instrE,
    input wire [31:0] instrM,
    input wire [31:0] addressE,  //save and load 
    input wire [31:0] addressM,  //load address

    input wire [31:0] data_wdataE, //要写的数据
    input wire [31:0] rt_valueM,   //rt寄存器的值
    output reg [31:0] writedataE,  //真正写数据
    output reg [3:0] mem_write_selectE,  //选择写哪一位

    input wire [31:0] mem_rdataM, //内存读出
    output reg [31:0] data_rdataM,  // 实际读出
    output wire [31:0] data_addrE,
    output reg [1:0] data_size, 
    output wire addr_error_sw, addr_error_lw
);
    wire [3:0] mem_byte_wen;
    wire [5:0] op_codeE;
    wire [5:0] op_codeM;

    wire addr_W0E, addr_B2E, addr_B1E, addr_B3E;
    wire addr_W0M, addr_B2M, addr_B1M, addr_B3M;
    
    assign op_codeE = instrE[31:26];
    assign op_codeM = instrM[31:26];
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

    // 判断是否为各种访存指令
    wire instr_lw = (op_codeM == `LW);
    wire instr_lb = (op_codeM == `LB);
    wire instr_lh = (op_codeM == `LH);
    wire instr_lbu = (op_codeM == `LBU);
    wire instr_lhu = (op_codeM == `LHU);
    wire instr_sw = (op_codeE == `SW); 
    wire instr_sh = (op_codeE == `SH);
    wire instr_sb = (op_codeE == `SB);

    wire instr_lwl = (op_codeM == `LWL);
    wire instr_lwr = (op_codeM == `LWR);
    
    wire instr_ll = (op_codeM == `LL);
    wire instr_sc = (op_codeE == `SC);

    wire instr_swl = (op_codeE == `SWL);
    wire instr_swr = (op_codeE == `SWR);


    wire instr_lwE = (op_codeE == `LW);
    wire instr_lhE = (op_codeE == `LH);
    wire instr_lhuE = (op_codeE == `LHU);
    wire instr_llE = (op_codeE == `LL);

    // 地址异常
    assign addr_error_sw = (instr_sw & ~addr_W0E)
                        | (  instr_sh & ~(addr_W0E | addr_B2E))
                        | (  instr_sc & ~addr_W0E);
    assign addr_error_lw = (instr_lwE & ~addr_W0E)
                        | (( instr_lhE | instr_lhuE ) & ~(addr_W0E | addr_B2E))
                        | (instr_llE & ~addr_W0E);

    always@(*)begin
        writedataE = 32'b0;
        case(op_codeE)
            `SW: begin
                data_size = 2'd2;
                mem_write_selectE = {4{addressE[1:0]==2'b00}} & 4'b1111;
                writedataE = data_wdataE;
            end
            `SWL: begin
                data_size = 2'd2;
                mem_write_selectE = ~((4'b1110) << addressE[1:0]); // ~ 按位取反
                writedataE = {32{addressE[1:0]==2'b11}} & (data_wdataE      ) |
                                  {32{addressE[1:0]==2'b10}} & (data_wdataE >> 8 ) |
                                  {32{addressE[1:0]==2'b01}} & (data_wdataE >> 16) |
                                  {32{addressE[1:0]==2'b00}} & (data_wdataE >> 24) ;
            end
            `SWR: begin
                data_size = 2'd2;
                mem_write_selectE = (4'b1111) << addressE[1:0]; // ~ 按位取反
                writedataE = {32{addressE[1:0]==2'b11}} & (data_wdataE << 24) |
                                  {32{addressE[1:0]==2'b10}} & (data_wdataE << 16) |
                                  {32{addressE[1:0]==2'b01}} & (data_wdataE << 8 ) |
                                  {32{addressE[1:0]==2'b00}} & (data_wdataE      ) ;
            end
            `SC: begin
                data_size = 2'd2;
                mem_write_selectE = {4{addressE[1:0]==2'b00}} & 4'b1111;
                writedataE = data_wdataE;
            end
            `SH: begin
                data_size = 2'd1;
                mem_write_selectE = {4{addressE[1:0]==2'b10}} & 4'b1100 |
                                {4{addressE[1:0]==2'b00}} & 4'b0011 ;
                writedataE = {data_wdataE[15:0],data_wdataE[15:0]};
            end
            `SB: begin
                data_size = 2'd0;
                mem_write_selectE = {4{addressE[1:0]==2'b11}} & 4'b1000 |
                                {4{addressE[1:0]==2'b10}} & 4'b0100 |
                                {4{addressE[1:0]==2'b01}} & 4'b0010 |
                                {4{addressE[1:0]==2'b00}} & 4'b0001 ;
                writedataE = {data_wdataE[7:0],data_wdataE[7:0],data_wdataE[7:0],data_wdataE[7:0]};
            end
            `LW: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd2;
            end
            `LL: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd2;
            end
            `LH: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd1;
            end
            `LHU: begin
                mem_write_selectE = 4'b0000;
                data_size = 2'd1;
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
                data_rdataM = {32{addressM[1:0]==2'b10}} & {{16{mem_rdataM[31]}},mem_rdataM[31:16]} |
                            {32{addressM[1:0]==2'b00}} & {{16{mem_rdataM[15]}},mem_rdataM[15: 0]} ;
            end
            `LHU: begin
                data_rdataM = {32{addressM[1:0]==2'b10}} & {{16{1'b0}},mem_rdataM[31:16]} |
                            {32{addressM[1:0]==2'b00}} & {{16{1'b0}},mem_rdataM[15: 0]} ;
            end
            `LB: begin
                data_rdataM = {32{addressM[1:0]==2'b11}} & {{24{mem_rdataM[31]}},mem_rdataM[31:24]} |
                            {32{addressM[1:0]==2'b10}} & {{24{mem_rdataM[23]}},mem_rdataM[23:16]} |
                            {32{addressM[1:0]==2'b01}} & {{24{mem_rdataM[15]}},mem_rdataM[15: 8]} |
                            {32{addressM[1:0]==2'b00}} & {{24{mem_rdataM[ 7]}},mem_rdataM[7 : 0]} ;
            end
            `LBU: begin
                data_rdataM = {32{addressM[1:0]==2'b11}} & {{24{1'b0}},mem_rdataM[31:24]} |
                            {32{addressM[1:0]==2'b10}} & {{24{1'b0}},mem_rdataM[23:16]} |
                            {32{addressM[1:0]==2'b01}} & {{24{1'b0}},mem_rdataM[15: 8]} |
                            {32{addressM[1:0]==2'b00}} & {{24{1'b0}},mem_rdataM[7 : 0]} ;
            end
            `LWL: begin
                data_rdataM = {32{addressM[1:0]==2'b11}} & ((mem_rdataM      ) | (rt_valueM & 32'h0       )) |
                            {32{addressM[1:0]==2'b10}} & ((mem_rdataM << 8 ) | (rt_valueM & 32'h000000ff)) |
                            {32{addressM[1:0]==2'b01}} & ((mem_rdataM << 16) | (rt_valueM & 32'h0000ffff)) |
                            {32{addressM[1:0]==2'b00}} & ((mem_rdataM << 24) | (rt_valueM & 32'h00ffffff)) ;
            end
            `LWR: begin
                data_rdataM = {32{addressM[1:0]==2'b11}} & ((mem_rdataM >> 24) | (rt_valueM & 32'hffffff00)) |
                            {32{addressM[1:0]==2'b10}} & ((mem_rdataM >> 16) | (rt_valueM & 32'hffff0000)) |
                            {32{addressM[1:0]==2'b01}} & ((mem_rdataM >> 8 ) | (rt_valueM & 32'hff000000)) |
                            {32{addressM[1:0]==2'b00}} & ((mem_rdataM      ) | (rt_valueM & 32'h0       )) ;
            end
            default:begin
                data_rdataM = 32'b0 ;
            end
        endcase
    end
endmodule