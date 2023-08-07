`include "defines2.vh"

module mem_control(
    input wire [31:0] instr1M, instr2M,
    input wire [31:0] instr1M2, instr2M2,
    input wire [31:0] address1M, address2M,  //save and load 
    input wire [31:0] address1M2, address2M2, //load address
    input wire mem_sel,

    input wire [31:0] data_wdata1M, data_wdata2M, //要写的数据
    input wire [31:0] rt_value1M2, rt_value2M2,  //rt寄存器的值
    output wire [31:0] writedataM,  //真正写数据
    output wire [3:0] mem_write_selectM,  //选择写哪一位

    input wire [31:0] mem_rdataM2, //内存读出
    output wire [31:0] data_rdataM2,  // 实际读出
    output wire [31:0] data_addrM,
    output wire addr_error_sw1, addr_error_lw1, addr_error_sw2, addr_error_lw2
);
    // 以下是新增的双发射控制逻辑和信号
    wire [5:0] op_code1M, op_code2M;
    wire [5:0] op_code1M2, op_code2M2;
    wire instr1_lw, instr1_lh, instr1_lb, instr1_sw, instr1_sh, instr1_sb, instr1_lhu, instr1_lbu;
    wire instr2_lw, instr2_lh, instr2_lb, instr2_sw, instr2_sh, instr2_sb, instr2_lhu, instr2_lbu;
    wire instr1_lwl, instr1_lwr, instr1_swl, instr1_swr;
    wire instr2_lwl, instr2_lwr, instr2_swl, instr2_swr;
    wire instr1_ll, instr1_sc, instr2_ll, instr2_sc;
    wire addr1_W01M, addr1_B21M, addr1_B11M, addr1_B31M;
    wire addr1_W01M2, addr1_B21M2, addr1_B11M2, addr1_B31M2;
    wire addr2_W01M, addr2_B21M, addr2_B11M, addr2_B31M;
    wire addr2_W01M2, addr2_B21M2, addr2_B11M2, addr2_B31M2;

    // 下面的assign语句将instrM和instrM2切分为两条指令的操作码
    assign op_code1M = instr1M[31:26];
    assign op_code2M = instr2M[25:20];
    assign op_code1M2 = instr1M2[31:26];
    assign op_code2M2 = instr2M2[25:20];

    assign data_addrM = mem_sel ? address1M: address2M;

    // 判断是否为各种访存指令
    assign instr1_lw = (op_code1M == `LW);
    assign instr1_lb = (op_code1M == `LB);
    assign instr1_lh = (op_code1M == `LH);
    assign instr1_lbu = (op_code1M == `LBU);
    assign instr1_lhu = (op_code1M == `LHU);
    assign instr1_sw = (op_code1M == `SW);
    assign instr1_sh = (op_code1M == `SH);
    assign instr1_sb = (op_code1M == `SB);

    assign instr2_lw = (op_code2M == `LW);
    assign instr2_lb = (op_code2M == `LB);
    assign instr2_lh = (op_code2M == `LH);
    assign instr2_lbu = (op_code2M == `LBU);
    assign instr2_lhu = (op_code2M == `LHU);
    assign instr2_sw = (op_code2M == `SW);
    assign instr2_sh = (op_code2M == `SH);
    assign instr2_sb = (op_code2M == `SB);

    // 下面是双发射阶段的地址计算逻辑
    assign addr1_W01M = address1M[1:0] == 2'b00;
    assign addr1_B21M = address1M[1:0] == 2'b10;
    assign addr1_B11M = address1M[1:0] == 2'b01;
    assign addr1_B31M = address1M[1:0] == 2'b11;
    
    assign addr2_W01M = address2M[1:0] == 2'b00;
    assign addr2_B21M = address2M[1:0] == 2'b10;
    assign addr2_B11M = address2M[1:0] == 2'b01;
    assign addr2_B31M = address2M[1:0] == 2'b11;

    assign addr1_W01M2 = address1M2[1:0] == 2'b00;
    assign addr1_B21M2 = address1M2[1:0] == 2'b10;
    assign addr1_B11M2 = address1M2[1:0] == 2'b01;
    assign addr1_B31M2 = address1M2[1:0] == 2'b11;

    assign addr2_W01M2 = address2M2[1:0] == 2'b00;
    assign addr2_B21M2 = address2M2[1:0] == 2'b10;
    assign addr2_B11M2 = address2M2[1:0] == 2'b01;
    assign addr2_B31M2 = address2M2[1:0] == 2'b11;

    // 下面是双发射阶段的其他控制逻辑
    assign instr1_lwl = ~(|(op_code1M2 ^ `LWL));
    assign instr1_lwr = ~(|(op_code1M2 ^ `LWR));
    assign instr1_ll = ~(|(op_code1M2 ^ `LL));

    assign instr1_sc = ~(|(op_code1M ^ `SC));
    assign instr1_swl = ~(|(op_code1M ^ `SWL));
    assign instr1_swr = ~(|(op_code1M ^ `SWR));
    
    assign instr1_lwM = ~(|(op_code1M ^ `LW));
    assign instr1_lhM = ~(|(op_code1M ^ `LH));
    assign instr1_lhuM = ~(|(op_code1M ^ `LHU));
    assign instr1_llM = ~(|(op_code1M ^ `LL));

    assign instr2_lwl = ~(|(op_code2M2 ^ `LWL));
    assign instr2_lwr = ~(|(op_code2M2 ^ `LWR));
    assign instr2_ll = ~(|(op_code2M2 ^ `LL));

    assign instr2_sc = ~(|(op_code2M ^ `SC));
    assign instr2_swl = ~(|(op_code2M ^ `SWL));
    assign instr2_swr = ~(|(op_code2M ^ `SWR));
    
    assign instr2_lwM = ~(|(op_code2M ^ `LW));
    assign instr2_lhM = ~(|(op_code2M ^ `LH));
    assign instr2_lhuM = ~(|(op_code2M ^ `LHU));
    assign instr2_llM = ~(|(op_code2M ^ `LL));




    // 地址异常
    assign addr_error_sw1 = (instr1_sw | instr1_sc & ~addr1_W01M)
                    | (instr1_sh & ~(addr1_W01M | addr1_B21M));

    assign addr_error_lw1 = (instr1_lwM | instr1_llM & ~addr1_W01M)
                    | ((instr1_lhM | instr1_lhuM) & ~(addr1_W01M | addr1_B21M));

    assign addr_error_sw2 = (instr2_sw | instr2_sc & ~addr1_W02M)
                    | (instr2_sh & ~(addr1_W02M | addr1_B22M));

    assign addr_error_lw2 = (instr2_lwM | instr2_llM & ~addr1_W02M)
                    | ((instr2_lhM | instr2_lhuM) & ~(addr1_W02M | addr1_B22M));

// wdata  and  byte_wen
    assign mem_write_selectM =( {4{( instr1_sw & addr1_W0M | instr2_sw & addr2_W0M)}} & 4'b1111)
                            | ( {4{( instr1_sh & addr1_W0M | instr2_sh & addr2_W0M)}} & 4'b0011)     //写半字 低位
                            | ( {4{( instr1_sh & addr1_B2M | instr2_sh & addr2_B2M)}} & 4'b1100)     //写半字 高位
                            | ( {4{( instr1_sb & addr1_W0M | instr2_sb & addr2_W0M)}} & 4'b0001)     //写字节 四个字节
                            | ( {4{( instr1_sb & addr1_B1M | instr2_sb & addr2_B1M)}} & 4'b0010)
                            | ( {4{( instr1_sb & addr1_B2M | instr2_sb & addr2_B2M)}} & 4'b0100)
                            | ( {4{( instr1_sb & addr1_B3M | instr2_sb & addr2_B3M)}} & 4'b1000)
                            | ( {4{( instr1_swl & addr1_W0M | instr2_swl & addr2_W0M)}} & 4'b0001)
                            | ( {4{( instr1_swl & addr1_B1M | instr2_swl & addr2_B1M)}} & 4'b0011)
                            | ( {4{( instr1_swl & addr1_B2M | instr2_swl & addr2_B2M)}} & 4'b0111)
                            | ( {4{( instr1_swl & addr1_B3M | instr2_swl & addr2_B3M)}} & 4'b1111)
                            | ( {4{( instr1_swr & addr1_W0M | instr2_swr & addr2_W0M)}} & 4'b1111)
                            | ( {4{( instr1_swr & addr1_B1M | instr2_swr & addr2_B1M)}} & 4'b1110)
                            | ( {4{( instr1_swr & addr1_B2M | instr2_swr & addr2_B2M)}} & 4'b1100)
                            | ( {4{( instr1_swr & addr1_B3M | instr2_swr & addr2_B3M)}} & 4'b1000);


// data ram 按字寻址
    assign writedataM =   ({ 32{instr1_sw}} & data_wdata1M)               //
                        | ( {32{instr1_sh}}  & {2{data_wdata1M[15:0]}  })  // 低位高位均为数据 具体根据操作
                        | ( {32{instr1_sb}}  & {4{data_wdata1M[7:0]}  })
                        | ( {32{instr1_swl & addr1_W0M}} & {4{data_wdata1M[31:24]}})
                        | ( {32{instr1_swl & addr1_B1M}} & {2{data_wdata1M[31:16]}})
                        | ( {32{instr1_swl & addr1_B2M}} & {8'b0, data_wdata1M[31:8]})
                        | ( {32{instr1_swl & addr1_B3M}} & data_wdata1M)
                        | ( {32{instr1_swr & addr1_W0M}} & data_wdata1M)
                        | ( {32{instr1_swr & addr1_B1M}} & {data_wdata1M[23:0], 8'b0})
                        | ( {32{instr1_swr & addr1_B2M}} & {2{data_wdata1M[15:0]}})
                        | ( {32{instr1_swr & addr1_B3M}} & {4{data_wdata1M[7:0]}})
                        | ({ 32{instr2_sw}}  & data_wdata2M)               //
                        | ( {32{instr2_sh}}  & {2{data_wdata2M[15:0]}  })  // 低位高位均为数据 具体根据操作
                        | ( {32{instr2_sb}}  & {4{data_wdata2M[7:0]}  })
                        | ( {32{instr2_swl & addr2_W0M}} & {4{data_wdata2M[31:24]}})
                        | ( {32{instr2_swl & addr2_B1M}} & {2{data_wdata2M[31:16]}})
                        | ( {32{instr2_swl & addr2_B2M}} & {8'b0, data_wdata2M[31:8]})
                        | ( {32{instr2_swl & addr2_B3M}} & data_wdata2M)
                        | ( {32{instr2_swr & addr2_W0M}} & data_wdata2M)
                        | ( {32{instr2_swr & addr2_B1M}} & {data_wdata2M[23:0], 8'b0})
                        | ( {32{instr2_swr & addr2_B2M}} & {2{data_wdata2M[15:0]}})
                        | ( {32{instr2_swr & addr2_B3M}} & {4{data_wdata2M[7:0]}});

// rdata   
    assign data_rdataM2 =  ( {32{instr1_lw | instr2_lw}}   & mem_rdataM2)
        | ( {32{instr1_lh & addr1_W0M2 | instr2_lh & addr2_W0M2}}  & { {16{mem_rdataM2[15]}},  mem_rdataM2[15:0]    })  
        | ( {32{instr1_lh & addr1_B2M2 | instr2_lh & addr2_B2M2}}  & { {16{mem_rdataM2[31]}},  mem_rdataM2[31:16]   })
        | ( {32{instr1_lhu & addr1_W0M2| instr2_lhu & addr2_W0M2}}  & {  16'b0,                mem_rdataM2[15:0]    })  //lhb 分别从00 10开始读半字 读取后进行0扩展
        | ( {32{instr1_lhu & addr1_B2M2| instr2_lhu & addr2_B2M2}}  & {  16'b0,                mem_rdataM2[31:16]   })
        | ( {32{instr1_lb & addr1_W0M2 | instr2_lb & addr2_W0M2}}  & { {24{mem_rdataM2[7]}},   mem_rdataM2[7:0]     })  //lb 分别从00 01 10 11开始取bytes 读取后进行符号扩展
        | ( {32{instr1_lb & addr1_B1M2 | instr2_lb & addr2_B1M2}}  & { {24{mem_rdataM2[15]}},  mem_rdataM2[15:8]    })
        | ( {32{instr1_lb & addr1_B2M2 | instr2_lb & addr2_B2M2}}  & { {24{mem_rdataM2[23]}},  mem_rdataM2[23:16]   })
        | ( {32{instr1_lb & addr1_B3M2 | instr2_lb & addr2_B3M2}}  & { {24{mem_rdataM2[31]}},  mem_rdataM2[31:24]   })
        | ( {32{instr1_lbu & addr1_W0M2| instr2_lbu & addr2_W0M2}}  & {  24'b0 ,               mem_rdataM2[7:0]     })  //lbu 分别从00 01 10 11开始取bytes 读取后进行0扩展
        | ( {32{instr1_lbu & addr1_B1M2| instr2_lbu & addr2_B1M2}}  & {  24'b0 ,               mem_rdataM2[15:8]    })
        | ( {32{instr1_lbu & addr1_B2M2| instr2_lbu & addr2_B2M2}}  & {  24'b0 ,               mem_rdataM2[23:16]   })
        | ( {32{instr1_lbu & addr1_B3M2| instr2_lbu & addr2_B3M2}}  & {  24'b0 ,               mem_rdataM2[31:24]   })
        | ( {32{instr1_lwl & addr1_W0M2| instr2_lwl & addr2_W0M2}}  & {  mem_rdataM2[7:0],           rt_valueM2[23:0]})
        | ( {32{instr1_lwl & addr1_B1M2| instr2_lwl & addr2_B1M2}}  & {  mem_rdataM2[15:0],          rt_valueM2[15:0]})
        | ( {32{instr1_lwl & addr1_B2M2| instr2_lwl & addr2_B2M2}}  & {  mem_rdataM2[23:0],          rt_valueM2[7:0]})
        | ( {32{instr1_lwl & addr1_B3M2| instr2_lwl & addr2_B3M2}}  & mem_rdataM2)
        | ( {32{instr1_lwr & addr1_W0M2| instr2_lwr & addr2_W0M2}}  & mem_rdataM2)
        | ( {32{instr1_lwr & addr1_B1M2| instr2_lwr & addr2_B1M2}}  & {  rt_valueM2[31:24],         mem_rdataM2[31:8]})
        | ( {32{instr1_lwr & addr1_B2M2| instr2_lwr & addr2_B2M2}}  & {  rt_valueM2[31:16],         mem_rdataM2[31:16]})
        | ( {32{instr1_lwr & addr1_B3M2| instr2_lwr & addr2_B3M2}}  & {  rt_valueM2[31:8],          mem_rdataM2[31:24]});
                        // | ( {32{instr1_ll}}  & mem_rdataM2)
                        // | ( {32{instr1_sc}}  & {31'b0, LLbit_out});

    // wire we = instr1_ll;
    // wire LLbit_out;
    // LLbit_reg llbit(.clk(clk), .rst(rst), .we(instr1_ll),
    //                 .LLbit_in(1'b1), .LLbit_out(LLbit_out));
endmodule
