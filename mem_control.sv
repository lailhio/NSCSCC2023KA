`include "defines2.vh"
`timescale 1ns / 1ps

module mem_control(
    input wire [31:0] instrM,
    input wire [31:0] instrM2,
    input wire [31:0] addressM,  //save and load 
    input wire [31:0] addressM2,  //load address

    input wire [31:0] data_wdataM, //要写的数据
    input wire [31:0] rt_valueM2,   //rt寄存器的值
    output reg [31:0] writedataM,  //真正写数据
    output reg [3:0] mem_write_selectM,  //选择写哪一位

    input wire [31:0] mem_rdataM2, //内存读出
    output reg [31:0] data_rdataM2,  // 实际读出
    output wire [31:0] data_addrM,
    output reg [1:0] data_size, 
    output wire addr_error_sw, addr_error_lw
);
    wire [3:0] mem_byte_wen;
    wire [5:0] op_codeM;
    wire [5:0] op_codeM2;

    wire addr_W0M, addr_B2M, addr_B1M, addr_B3M;
    wire addr_W0M2, addr_B2M2, addr_B1M2, addr_B3M2;
    
    assign op_codeM = instrM[31:26];
    assign op_codeM2 = instrM2[31:26];
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

    // 判断是否为各种访存指令
    wire instr_lw = (op_codeM2 == `LW);
    wire instr_lb = (op_codeM2 == `LB);
    wire instr_lh = (op_codeM2 == `LH);
    wire instr_lbu = (op_codeM2 == `LBU);
    wire instr_lhu = (op_codeM2 == `LHU);
    wire instr_sw = (op_codeM == `SW); 
    wire instr_sh = (op_codeM == `SH);
    wire instr_sb = (op_codeM == `SB);

    wire instr_lwl = (op_codeM2 == `LWL);
    wire instr_lwr = (op_codeM2 == `LWR);
    
    wire instr_ll = (op_codeM2 == `LL);
    wire instr_sc = (op_codeM == `SC);

    wire instr_swl = (op_codeM == `SWL);
    wire instr_swr = (op_codeM == `SWR);


    wire instr_lwM = (op_codeM == `LW);
    wire instr_lhM = (op_codeM == `LH);
    wire instr_lhuM = (op_codeM == `LHU);
    wire instr_llM = (op_codeM == `LL);

    // 地址异常
    assign addr_error_sw = (instr_sw & ~addr_W0M)
                        | (  instr_sh & ~(addr_W0M | addr_B2M))
                        | (  instr_sc & ~addr_W0M);
    assign addr_error_lw = (instr_lwM & ~addr_W0M)
                        | (( instr_lhM | instr_lhuM ) & ~(addr_W0M | addr_B2M))
                        | (instr_llM & ~addr_W0M);

    always@(*)begin
        writedataM = 32'b0;
        case(op_codeM)
            `SW: begin
                data_size = 2'd2;
                mem_write_selectM = {4{addressM[1:0]==2'b00}} & 4'b1111;
                writedataM = data_wdataM;
            end
            `SWL: begin
                data_size = 2'd2;
                mem_write_selectM = ~((4'b1110) << addressM[1:0]); // ~ 按位取反
                writedataM = {32{addressM[1:0]==2'b11}} & (data_wdataM      ) |
                                  {32{addressM[1:0]==2'b10}} & (data_wdataM >> 8 ) |
                                  {32{addressM[1:0]==2'b01}} & (data_wdataM >> 16) |
                                  {32{addressM[1:0]==2'b00}} & (data_wdataM >> 24) ;
            end
            `SWR: begin
                data_size = 2'd2;
                mem_write_selectM = (4'b1111) << addressM[1:0]; // ~ 按位取反
                writedataM = {32{addressM[1:0]==2'b11}} & (data_wdataM << 24) |
                                  {32{addressM[1:0]==2'b10}} & (data_wdataM << 16) |
                                  {32{addressM[1:0]==2'b01}} & (data_wdataM << 8 ) |
                                  {32{addressM[1:0]==2'b00}} & (data_wdataM      ) ;
            end
            `SC: begin
                data_size = 2'd2;
                mem_write_selectM = {4{addressM[1:0]==2'b00}} & 4'b1111;
                writedataM = data_wdataM;
            end
            `SH: begin
                data_size = 2'd1;
                mem_write_selectM = {4{addressM[1:0]==2'b10}} & 4'b1100 |
                                {4{addressM[1:0]==2'b00}} & 4'b0011 ;
                writedataM = {data_wdataM[15:0],data_wdataM[15:0]};
            end
            `SB: begin
                data_size = 2'd0;
                mem_write_selectM = {4{addressM[1:0]==2'b11}} & 4'b1000 |
                                {4{addressM[1:0]==2'b10}} & 4'b0100 |
                                {4{addressM[1:0]==2'b01}} & 4'b0010 |
                                {4{addressM[1:0]==2'b00}} & 4'b0001 ;
                writedataM = {data_wdataM[7:0],data_wdataM[7:0],data_wdataM[7:0],data_wdataM[7:0]};
            end
            `LW: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd2;
            end
            `LL: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd2;
            end
            `LH: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd1;
            end
            `LHU: begin
                mem_write_selectM = 4'b0000;
                data_size = 2'd1;
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
                data_rdataM2 = {32{addressM2[1:0]==2'b10}} & {{16{mem_rdataM2[31]}},mem_rdataM2[31:16]} |
                            {32{addressM2[1:0]==2'b00}} & {{16{mem_rdataM2[15]}},mem_rdataM2[15: 0]} ;
            end
            `LHU: begin
                data_rdataM2 = {32{addressM2[1:0]==2'b10}} & {{16{1'b0}},mem_rdataM2[31:16]} |
                            {32{addressM2[1:0]==2'b00}} & {{16{1'b0}},mem_rdataM2[15: 0]} ;
            end
            `LB: begin
                data_rdataM2 = {32{addressM2[1:0]==2'b11}} & {{24{mem_rdataM2[31]}},mem_rdataM2[31:24]} |
                            {32{addressM2[1:0]==2'b10}} & {{24{mem_rdataM2[23]}},mem_rdataM2[23:16]} |
                            {32{addressM2[1:0]==2'b01}} & {{24{mem_rdataM2[15]}},mem_rdataM2[15: 8]} |
                            {32{addressM2[1:0]==2'b00}} & {{24{mem_rdataM2[ 7]}},mem_rdataM2[7 : 0]} ;
            end
            `LBU: begin
                data_rdataM2 = {32{addressM2[1:0]==2'b11}} & {{24{1'b0}},mem_rdataM2[31:24]} |
                            {32{addressM2[1:0]==2'b10}} & {{24{1'b0}},mem_rdataM2[23:16]} |
                            {32{addressM2[1:0]==2'b01}} & {{24{1'b0}},mem_rdataM2[15: 8]} |
                            {32{addressM2[1:0]==2'b00}} & {{24{1'b0}},mem_rdataM2[7 : 0]} ;
            end
            `LWL: begin
                data_rdataM2 = {32{addressM2[1:0]==2'b11}} & ((mem_rdataM2      ) | (rt_valueM2 & 32'h0       )) |
                            {32{addressM2[1:0]==2'b10}} & ((mem_rdataM2 << 8 ) | (rt_valueM2 & 32'h000000ff)) |
                            {32{addressM2[1:0]==2'b01}} & ((mem_rdataM2 << 16) | (rt_valueM2 & 32'h0000ffff)) |
                            {32{addressM2[1:0]==2'b00}} & ((mem_rdataM2 << 24) | (rt_valueM2 & 32'h00ffffff)) ;
            end
            `LWR: begin
                data_rdataM2 = {32{addressM2[1:0]==2'b11}} & ((mem_rdataM2 >> 24) | (rt_valueM2 & 32'hffffff00)) |
                            {32{addressM2[1:0]==2'b10}} & ((mem_rdataM2 >> 16) | (rt_valueM2 & 32'hffff0000)) |
                            {32{addressM2[1:0]==2'b01}} & ((mem_rdataM2 >> 8 ) | (rt_valueM2 & 32'hff000000)) |
                            {32{addressM2[1:0]==2'b00}} & ((mem_rdataM2      ) | (rt_valueM2 & 32'h0       )) ;
            end
            default:begin
                data_rdataM2 = 32'b0 ;
            end
        endcase
    end
endmodule