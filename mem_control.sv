`include "defines2.vh"

module mem_control(
    input wire [31:0] instr1M, instr2M,
    input wire [31:0] instr1M2, instr2M2,
    input wire [31:0] address1M, address2M,  //save and load 
    input wire [31:0] address1M2, address2M2, //load address
    input wire mem_sel, Blank_SL,

    input wire [31:0] data_wdata1M, data_wdata2M, //要写的数据
    input wire [31:0] rt_valueM2,  //rt寄存器的值
    output wire [31:0] writedataM, writedataW, //真正写数据
    output wire [3:0] mem_write_selectM, mem_write_selectW, //选择写哪一位

    input wire [31:0] mem_rdataM2, //内存读出
    output wire [31:0] data_rdataM2,  // 实际读出
    output wire [31:0] data_srcM,
    output wire [31:0] data_addrM,
    output wire addr_error_sw1, addr_error_lw1, addr_error_sw2, addr_error_lw2
);
    // 以下是新增的双发射控制逻辑和信号
    wire [5:0] op_code1M, op_code2M;
    wire [5:0] op_code1M2, op_code2M2;
    wire addr1_W01M, addr1_B21M, addr1_B11M, addr1_B31M;
    wire addr1_W01M2, addr1_B21M2, addr1_B11M2, addr1_B31M2;
    wire addr2_W01M, addr2_B21M, addr2_B11M, addr2_B31M;
    wire addr2_W01M2, addr2_B21M2, addr2_B11M2, addr2_B31M2;

    // 下面的assign语句将instrM和instrM2切分为两条指令的操作码
    assign op_code1M = instr1M[31:26];
    assign op_code2M = instr2M[31:26];
    assign op_code1M2 = instr1M2[31:26];
    assign op_code2M2 = instr2M2[31:26];

    assign data_addrM = mem_sel ? address1M: address2M;
    assign data_srcM = mem_sel ? data_wdata1M: data_wdata2M;

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
    // 判断是否为各种访存指令
    wire instr1_lw = (op_code1M2 == `LW);
    wire instr1_lb = (op_code1M2 == `LB);
    wire instr1_lh = (op_code1M2 == `LH);
    wire instr1_lbu = (op_code1M2 == `LBU);
    wire instr1_lhu = (op_code1M2 == `LHU);

    wire instr1_sw = (op_code1M == `SW);
    wire instr1_sh = (op_code1M == `SH);
    wire instr1_sb = (op_code1M == `SB);

    wire instr2_lw = (op_code2M2 == `LW);
    wire instr2_lb = (op_code2M2 == `LB);
    wire instr2_lh = (op_code2M2 == `LH);
    wire instr2_lbu = (op_code2M2 == `LBU);
    wire instr2_lhu = (op_code2M2 == `LHU);

    wire instr2_sw = (op_code2M == `SW);
    wire instr2_sh = (op_code2M == `SH);
    wire instr2_sb = (op_code2M == `SB);

    wire instr1_lwl = (op_code1M2 == `LWL);
    wire instr1_lwr = (op_code1M2 == `LWR);
    wire instr1_ll = (op_code1M2 == `LL);

    wire instr1_sc = (op_code1M == `SC);
    wire instr1_swl = (op_code1M == `SWL);
    wire instr1_swr = (op_code1M == `SWR);

    wire instr1_lwM = (op_code1M == `LW);
    wire instr1_lhM = (op_code1M == `LH);
    wire instr1_lhuM = (op_code1M == `LHU);
    wire instr1_llM = (op_code1M == `LL);

    wire instr2_lwl = (op_code2M2 == `LWL);
    wire instr2_lwr = (op_code2M2 == `LWR);
    wire instr2_ll = (op_code2M2 == `LL);

    wire instr2_sc = (op_code2M == `SC);
    wire instr2_swl = (op_code2M == `SWL);
    wire instr2_swr = (op_code2M == `SWR);

    wire instr2_lwM = (op_code2M == `LW);
    wire instr2_lhM = (op_code2M == `LH);
    wire instr2_lhuM = (op_code2M == `LHU);
    wire instr2_llM = (op_code2M == `LL);





    // 地址异常
    assign addr_error_sw1 = ((instr1_sw | instr1_sc) & ~addr1_W01M)
                    | (instr1_sh & ~(addr1_W01M | addr1_B21M));

    assign addr_error_lw1 = ((instr1_lwM | instr1_llM) & ~addr1_W01M)
                    | ((instr1_lhM | instr1_lhuM) & ~(addr1_W01M | addr1_B21M));

    assign addr_error_sw2 = ((instr2_sw | instr2_sc) & ~addr2_W01M)
                    | (instr2_sh & ~(addr2_W01M | addr2_B21M));

    assign addr_error_lw2 = ((instr2_lwM | instr2_llM) & ~addr2_W01M)
                    | ((instr2_lhM | instr2_lhuM) & ~(addr2_W01M | addr2_B21M));

// wdata  and  byte_wen
    assign mem_write_selectM =( {4{( instr1_sw & addr1_W01M | instr2_sw & addr2_W01M)}} & 4'b1111)
                            | ( {4{( instr1_sh & addr1_W01M | instr2_sh & addr2_W01M)}} & 4'b0011)     //写半字 低位
                            | ( {4{( instr1_sh & addr1_B21M | instr2_sh & addr2_B21M)}} & 4'b1100)     //写半字 高位
                            | ( {4{( instr1_sb & addr1_W01M | instr2_sb & addr2_W01M)}} & 4'b0001)     //写字节 四个字节
                            | ( {4{( instr1_sb & addr1_B11M | instr2_sb & addr2_B11M)}} & 4'b0010)
                            | ( {4{( instr1_sb & addr1_B21M | instr2_sb & addr2_B21M)}} & 4'b0100)
                            | ( {4{( instr1_sb & addr1_B31M | instr2_sb & addr2_B31M)}} & 4'b1000)
                            | ( {4{( instr1_swl & addr1_W01M | instr2_swl & addr2_W01M)}} & 4'b0001)
                            | ( {4{( instr1_swl & addr1_B11M | instr2_swl & addr2_B11M)}} & 4'b0011)
                            | ( {4{( instr1_swl & addr1_B21M | instr2_swl & addr2_B21M)}} & 4'b0111)
                            | ( {4{( instr1_swl & addr1_B31M | instr2_swl & addr2_B31M)}} & 4'b1111)
                            | ( {4{( instr1_swr & addr1_W01M | instr2_swr & addr2_W01M)}} & 4'b1111)
                            | ( {4{( instr1_swr & addr1_B11M | instr2_swr & addr2_B11M)}} & 4'b1110)
                            | ( {4{( instr1_swr & addr1_B21M | instr2_swr & addr2_B21M)}} & 4'b1100)
                            | ( {4{( instr1_swr & addr1_B31M | instr2_swr & addr2_B31M)}} & 4'b1000);


// data ram 按字寻址
    assign writedataM =   ({ 32{instr1_sw}} & data_wdata1M)               //
                        | ( {32{instr1_sh}}  & {2{data_wdata1M[15:0]}  })  // 低位高位均为数据 具体根据操作
                        | ( {32{instr1_sb}}  & {4{data_wdata1M[7:0]}  })
                        | ( {32{instr1_swl & addr1_W01M}} & {4{data_wdata1M[31:24]}})
                        | ( {32{instr1_swl & addr1_B11M}} & {2{data_wdata1M[31:16]}})
                        | ( {32{instr1_swl & addr1_B21M}} & {8'b0, data_wdata1M[31:8]})
                        | ( {32{instr1_swl & addr1_B31M}} & data_wdata1M)
                        | ( {32{instr1_swr & addr1_W01M}} & data_wdata1M)
                        | ( {32{instr1_swr & addr1_B11M}} & {data_wdata1M[23:0], 8'b0})
                        | ( {32{instr1_swr & addr1_B21M}} & {2{data_wdata1M[15:0]}})
                        | ( {32{instr1_swr & addr1_B31M}} & {4{data_wdata1M[7:0]}})
                        | ({ 32{instr2_sw}}  & data_wdata2M)               //
                        | ( {32{instr2_sh}}  & {2{data_wdata2M[15:0]}  })  // 低位高位均为数据 具体根据操作
                        | ( {32{instr2_sb}}  & {4{data_wdata2M[7:0]}  })
                        | ( {32{instr2_swl & addr2_W01M}} & {4{data_wdata2M[31:24]}})
                        | ( {32{instr2_swl & addr2_B11M}} & {2{data_wdata2M[31:16]}})
                        | ( {32{instr2_swl & addr2_B21M}} & {8'b0, data_wdata2M[31:8]})
                        | ( {32{instr2_swl & addr2_B31M}} & data_wdata2M)
                        | ( {32{instr2_swr & addr2_W01M}} & data_wdata2M)
                        | ( {32{instr2_swr & addr2_B11M}} & {data_wdata2M[23:0], 8'b0})
                        | ( {32{instr2_swr & addr2_B21M}} & {2{data_wdata2M[15:0]}})
                        | ( {32{instr2_swr & addr2_B31M}} & {4{data_wdata2M[7:0]}});

// rdata   
    // wire [31:0] wforward_rdata = mem_rdataM2 & ~({32{Blank_SL}} & {{8{mem_write_selectW[3]}}, {8{mem_write_selectW[2]}}, {8{mem_write_selectW[1]}}, {8{mem_write_selectW[0]}}}) | 
    //                           writedataW & {32{Blank_SL}} & {{8{mem_write_selectW[3]}}, {8{mem_write_selectW[2]}}, {8{mem_write_selectW[1]}}, {8{mem_write_selectW[0]}}};
    
    assign data_rdataM2 =  ( {32{instr1_lw | instr2_lw}}   & mem_rdataM2)
        | ( {32{instr1_lh & addr1_W01M2 | instr2_lh & addr2_W01M2}}  & { {16{mem_rdataM2[15]}},  mem_rdataM2[15:0]    })  
        | ( {32{instr1_lh & addr1_B21M2 | instr2_lh & addr2_B21M2}}  & { {16{mem_rdataM2[31]}},  mem_rdataM2[31:16]   })
        | ( {32{instr1_lhu & addr1_W01M2| instr2_lhu & addr2_W01M2}}  & {  16'b0,                mem_rdataM2[15:0]    })  //lhb 分别从00 10开始读半字 读取后进行0扩展
        | ( {32{instr1_lhu & addr1_B21M2| instr2_lhu & addr2_B21M2}}  & {  16'b0,                mem_rdataM2[31:16]   })
        | ( {32{instr1_lb & addr1_W01M2 | instr2_lb & addr2_W01M2}}  & { {24{mem_rdataM2[7]}},   mem_rdataM2[7:0]     })  //lb 分别从00 01 10 11开始取bytes 读取后进行符号扩展
        | ( {32{instr1_lb & addr1_B11M2 | instr2_lb & addr2_B11M2}}  & { {24{mem_rdataM2[15]}},  mem_rdataM2[15:8]    })
        | ( {32{instr1_lb & addr1_B21M2 | instr2_lb & addr2_B21M2}}  & { {24{mem_rdataM2[23]}},  mem_rdataM2[23:16]   })
        | ( {32{instr1_lb & addr1_B31M2 | instr2_lb & addr2_B31M2}}  & { {24{mem_rdataM2[31]}},  mem_rdataM2[31:24]   })
        | ( {32{instr1_lbu & addr1_W01M2| instr2_lbu & addr2_W01M2}}  & {  24'b0 ,               mem_rdataM2[7:0]     })  //lbu 分别从00 01 10 11开始取bytes 读取后进行0扩展
        | ( {32{instr1_lbu & addr1_B11M2| instr2_lbu & addr2_B11M2}}  & {  24'b0 ,               mem_rdataM2[15:8]    })
        | ( {32{instr1_lbu & addr1_B21M2| instr2_lbu & addr2_B21M2}}  & {  24'b0 ,               mem_rdataM2[23:16]   })
        | ( {32{instr1_lbu & addr1_B31M2| instr2_lbu & addr2_B31M2}}  & {  24'b0 ,               mem_rdataM2[31:24]   })
        | ( {32{instr1_lwl & addr1_W01M2| instr2_lwl & addr2_W01M2}}  & {  mem_rdataM2[7:0],           rt_valueM2[23:0]})
        | ( {32{instr1_lwl & addr1_B11M2| instr2_lwl & addr2_B11M2}}  & {  mem_rdataM2[15:0],          rt_valueM2[15:0]})
        | ( {32{instr1_lwl & addr1_B21M2| instr2_lwl & addr2_B21M2}}  & {  mem_rdataM2[23:0],          rt_valueM2[7:0]})
        | ( {32{instr1_lwl & addr1_B31M2| instr2_lwl & addr2_B31M2}}  &    mem_rdataM2)
        | ( {32{instr1_lwr & addr1_W01M2| instr2_lwr & addr2_W01M2}}  &    mem_rdataM2)
        | ( {32{instr1_lwr & addr1_B11M2| instr2_lwr & addr2_B11M2}}  & {  rt_valueM2[31:24],         mem_rdataM2[31:8]})
        | ( {32{instr1_lwr & addr1_B21M2| instr2_lwr & addr2_B21M2}}  & {  rt_valueM2[31:16],         mem_rdataM2[31:16]})
        | ( {32{instr1_lwr & addr1_B31M2| instr2_lwr & addr2_B31M2}}  & {  rt_valueM2[31:8],          mem_rdataM2[31:24]});
                        // | ( {32{instr1_ll}}  & wforward_rdata)
                        // | ( {32{instr1_sc}}  & {31'b0, LLbit_out});

    // wire we = instr1_ll;
    // wire LLbit_out;
    // LLbit_reg llbit(.clk(clk), .rst(rst), .we(instr1_ll),
    //                 .LLbit_in(1'b1), .LLbit_out(LLbit_out));
endmodule
