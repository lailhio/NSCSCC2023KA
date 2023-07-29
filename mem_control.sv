`include "defines2.vh"

module mem_control(
    input wire [31:0] instrM,
    input wire [31:0] instrM2,
    input wire [31:0] addressM,  //save and load 
    input wire [31:0] addressM2,  //load address

    input wire [31:0] data_wdataM, //要写的数据
    input wire [31:0] rt_valueM2,   //rt寄存器的值
    output wire [31:0] writedataM,  //真正写数据
    output wire [3:0] mem_write_selectM,  //选择写哪一位

    input wire [31:0] mem_rdataM2, //内存读出
    output wire [31:0] data_rdataM2,  // 实际读出
    output wire [31:0] data_addrM,
    output wire addr_error_sw, addr_error_lw
);
    wire [3:0] mem_byte_wen;
    wire [5:0] op_codeM;
    wire [5:0] op_codeM2;

    wire instr_lw, instr_lh, instr_lb, instr_sw, instr_sh, instr_sb, instr_lhu, instr_lbu;
    wire instr_lwl, instr_lwr, instr_swl, instr_swr;
    wire instr_ll, instr_sc;
    wire addr_W0M, addr_B2M, addr_B1M, addr_B3M;
    wire addr_W0M2, addr_B2M2, addr_B1M2, addr_B3M2;
    
    assign op_codeM = instrM[31:26];
    assign op_codeM2 = instrM2[31:26];
    assign data_addrM = addressM ; 
    // Load and save sel
    assign addr_W0M = ~(|(addressM[1:0] ^ 2'b00));
    assign addr_B2M = ~(|(addressM[1:0] ^ 2'b10));
    assign addr_B1M = ~(|(addressM[1:0] ^ 2'b01));
    assign addr_B3M = ~(|(addressM[1:0] ^ 2'b11));
    // Load  sel
    assign addr_W0M2 = ~(|(addressM2[1:0] ^ 2'b00));
    assign addr_B2M2 = ~(|(addressM2[1:0] ^ 2'b10));
    assign addr_B1M2 = ~(|(addressM2[1:0] ^ 2'b01));
    assign addr_B3M2 = ~(|(addressM2[1:0] ^ 2'b11));

    // 判断是否为各种访存指令
    assign instr_lw = ~(|(op_codeM2 ^ `LW));
    assign instr_lb = ~(|(op_codeM2 ^ `LB));
    assign instr_lh = ~(|(op_codeM2 ^ `LH));
    assign instr_lbu = ~(|(op_codeM2 ^ `LBU));
    assign instr_lhu = ~(|(op_codeM2 ^ `LHU));
    assign instr_sw = ~(|(op_codeM ^ `SW)); 
    assign instr_sh = ~(|(op_codeM ^ `SH));
    assign instr_sb = ~(|(op_codeM ^ `SB));

    assign instr_lwl = ~(|(op_codeM2 ^ `LWL));
    assign instr_lwr = ~(|(op_codeM2 ^ `LWR));
    
    assign instr_ll = ~(|(op_codeM2 ^ `LL));
    assign instr_sc = ~(|(op_codeM ^ `SC));

    assign instr_swl = ~(|(op_codeM ^ `SWL));
    assign instr_swr = ~(|(op_codeM ^ `SWR));


    assign instr_lwM = ~(|(op_codeM ^ `LW));
    assign instr_lhM = ~(|(op_codeM ^ `LH));
    assign instr_lhuM = ~(|(op_codeM ^ `LHU));
    assign instr_llM = ~(|(op_codeM ^ `LL));

    // 地址异常
    assign addr_error_sw = (instr_sw & ~addr_W0M)
                        | (  instr_sh & ~(addr_W0M | addr_B2M))
                        | (  instr_sc & ~addr_W0M);
    assign addr_error_lw = (instr_lwM & ~addr_W0M)
                        | (( instr_lhM | instr_lhuM ) & ~(addr_W0M | addr_B2M))
                        | (instr_llM & ~addr_W0M);

// wdata  and  byte_wen
    assign mem_write_selectM =     ( {4{( instr_sw & addr_W0M )}} & 4'b1111)          //写字  
                        | ( {4{( instr_sh & addr_W0M  )}} & 4'b0011)     //写半字 低位
                        | ( {4{( instr_sh & addr_B2M  )}} & 4'b1100)     //写半字 高位
                        | ( {4{( instr_sb & addr_W0M  )}} & 4'b0001)     //写字节 四个字节
                        | ( {4{( instr_sb & addr_B1M  )}} & 4'b0010)
                        | ( {4{( instr_sb & addr_B2M  )}} & 4'b0100)
                        | ( {4{( instr_sb & addr_B3M  )}} & 4'b1000)
                        | ( {4{( instr_swl & addr_W0M )}} & 4'b0001)
                        | ( {4{( instr_swl & addr_B1M )}} & 4'b0011)
                        | ( {4{( instr_swl & addr_B2M )}} & 4'b0111)
                        | ( {4{( instr_swl & addr_B3M )}} & 4'b1111)
                        | ( {4{( instr_swr & addr_W0M )}} & 4'b1111)
                        | ( {4{( instr_swr & addr_B1M )}} & 4'b1110)
                        | ( {4{( instr_swr & addr_B2M )}} & 4'b1100)
                        | ( {4{( instr_swr & addr_B3M )}} & 4'b1000);
                        // | ( {4{( instr_sc  & LLbit_out)}}) & 4'b1111;   //if LLbit then store


// data ram 按字寻址
    assign writedataM =   ({ 32{instr_sw}} & data_wdataM)               //
                        | ( {32{instr_sh}}  & {2{data_wdataM[15:0]}  })  // 低位高位均为数据 具体根据操作
                        | ( {32{instr_sb}}  & {4{data_wdataM[7:0]}  })
                        | ( {32{instr_swl & addr_W0M}} & {4{data_wdataM[31:24]}})
                        | ( {32{instr_swl & addr_B1M}} & {2{data_wdataM[31:16]}})
                        | ( {32{instr_swl & addr_B2M}} & {8'b0, data_wdataM[31:8]})
                        | ( {32{instr_swl & addr_B3M}} & data_wdataM)
                        | ( {32{instr_swr & addr_W0M}} & data_wdataM)
                        | ( {32{instr_swr & addr_B1M}} & {data_wdataM[23:0], 8'b0})
                        | ( {32{instr_swr & addr_B2M}} & {2{data_wdataM[15:0]}})
                        | ( {32{instr_swr & addr_B3M}} & {4{data_wdataM[7:0]}});
                        // | ( {32{instr_sc}} & data_wdataM); //
// rdata   
    assign data_rdataM2 =  ( {32{instr_lw}}   & mem_rdataM2)                                                  //lw 直接读取字
                        | ( {32{ instr_lh   & addr_W0M2}}  & { {16{mem_rdataM2[15]}},  mem_rdataM2[15:0]    })  //lh 分别从00 10开始读半字 读取后进行符号扩展
                        | ( {32{ instr_lh   & addr_B2M2}}  & { {16{mem_rdataM2[31]}},  mem_rdataM2[31:16]   })
                        | ( {32{ instr_lhu  & addr_W0M2}}  & {  16'b0,                mem_rdataM2[15:0]    })  //lhb 分别从00 10开始读半字 读取后进行0扩展
                        | ( {32{ instr_lhu  & addr_B2M2}}  & {  16'b0,                mem_rdataM2[31:16]   })
                        | ( {32{ instr_lb   & addr_W0M2}}  & { {24{mem_rdataM2[7]}},   mem_rdataM2[7:0]     })  //lb 分别从00 01 10 11开始取bytes 读取后进行符号扩展
                        | ( {32{ instr_lb   & addr_B1M2}}  & { {24{mem_rdataM2[15]}},  mem_rdataM2[15:8]    })
                        | ( {32{ instr_lb   & addr_B2M2}}  & { {24{mem_rdataM2[23]}},  mem_rdataM2[23:16]   })
                        | ( {32{ instr_lb   & addr_B3M2}}  & { {24{mem_rdataM2[31]}},  mem_rdataM2[31:24]   })
                        | ( {32{ instr_lbu  & addr_W0M2}}  & {  24'b0 ,               mem_rdataM2[7:0]     })  //lbu 分别从00 01 10 11开始取bytes 读取后进行0扩展
                        | ( {32{ instr_lbu  & addr_B1M2}}  & {  24'b0 ,               mem_rdataM2[15:8]    })
                        | ( {32{ instr_lbu  & addr_B2M2}}  & {  24'b0 ,               mem_rdataM2[23:16]   })
                        | ( {32{ instr_lbu  & addr_B3M2}}  & {  24'b0 ,               mem_rdataM2[31:24]   })
                        | ( {32{ instr_lwl  & addr_W0M2}}  & {  mem_rdataM2[7:0],           rt_valueM2[23:0]})
                        | ( {32{ instr_lwl  & addr_B1M2}}  & {  mem_rdataM2[15:0],          rt_valueM2[15:0]})
                        | ( {32{ instr_lwl  & addr_B2M2}}  & {  mem_rdataM2[23:0],          rt_valueM2[7:0]})
                        | ( {32{ instr_lwl  & addr_B3M2}}  & mem_rdataM2)
                        | ( {32{ instr_lwr  & addr_W0M2}}  & mem_rdataM2)
                        | ( {32{ instr_lwr  & addr_B1M2}}  & {  rt_valueM2[31:24],         mem_rdataM2[31:8]})
                        | ( {32{ instr_lwr  & addr_B2M2}}  & {  rt_valueM2[31:16],         mem_rdataM2[31:16]})
                        | ( {32{ instr_lwr  & addr_B3M2}}  & {  rt_valueM2[31:8],          mem_rdataM2[31:24]});
                        // | ( {32{instr_ll}}  & mem_rdataM2)
                        // | ( {32{instr_sc}}  & {31'b0, LLbit_out});

    // wire we = instr_ll;
    // wire LLbit_out;
    // LLbit_reg llbit(.clk(clk), .rst(rst), .we(instr_ll),
    //                 .LLbit_in(1'b1), .LLbit_out(LLbit_out));
endmodule
