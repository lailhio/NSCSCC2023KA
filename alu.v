`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/11/02 14:52:16
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu(
    input wire clk, rst,
    input wire flushE,
    input wire [31:0] src_aE, src_bE,  //操作数
    input wire [4:0] alucontrolE,  //alu 控制信号
    input wire [4:0] sa, //sa值
    input wire [63:0] hilo,  //hilo值

    output wire div_stallE,
    output wire [63:0] aluoutE, //alu输出
    output wire overflowE//算数溢出
);
    wire [63:0] aluout_div; //乘除法结果
    reg [63:0] aluout_mul;
    wire mul_sign; //乘法符号
    wire mul_valid;  // 为乘法
    wire div_sign; //除法符号
	wire div_vaild;  //为除法
	wire ready;
    reg [31:0] aluout_simple; // 普通运算结果
    reg carry_bit;  //进位 判断溢出


    //乘法信号
	assign mul_sign = (alucontrolE == `MULT_CONTROL);
    assign mul_valid = (alucontrolE == `MULT_CONTROL) | (alucontrolE == `MULTU_CONTROL);

    //aluout
    assign aluoutE = ({64{div_vaild}} & aluout_div)
                    | ({64{mul_valid}} & aluout_mul)
                    | ({64{~mul_valid & ~div_vaild}} & {32'b0, aluout_simple})
                    | ({64{(alucontrolE == `MTHI_CONTROL)}} & {src_aE, hilo[31:0]}) // 若为mthi/mtlo 直接取Hilo的低32位和高32位
                    | ({64{(alucontrolE == `MTLO_CONTROL)}} & {hilo[63:32], src_aE});
    // 为加减 且溢出位与最高位不等时 算数溢出
    assign overflowE = (alucontrolE==`ADD_CONTROL || alucontrolE==`SUB_CONTROL) & (carry_bit ^ aluout_simple[31]);

    // 算数操作及对应运算
    always @(*) begin
        carry_bit = 0; //溢出位取0
        case(alucontrolE)
            `AND_CONTROL:       aluout_simple = src_aE & src_bE;
            `OR_CONTROL:        aluout_simple = src_aE | src_bE;
            `NOR_CONTROL:       aluout_simple =~(src_aE | src_bE);
            `XOR_CONTROL:       aluout_simple = src_aE ^ src_bE;

            `ADD_CONTROL:       {carry_bit, aluout_simple} = {src_aE[31], src_aE} + {src_bE[31], src_bE};
            `ADDU_CONTROL:      aluout_simple = src_aE + src_bE;
            `SUB_CONTROL:       {carry_bit, aluout_simple} = {src_aE[31], src_aE} - {src_bE[31], src_bE};
            `SUBU_CONTROL:      aluout_simple = src_aE - src_bE;

            `SLT_CONTROL:       aluout_simple = $signed(src_aE) < $signed(src_bE); //有符号比较
            `SLTU_CONTROL:      aluout_simple = src_aE < src_bE; //无符号比较

            `SLLV_CONTROL:       aluout_simple = src_bE << src_aE[4:0]; //移位src a
            `SRLV_CONTROL:       aluout_simple = src_bE >> src_aE[4:0];
            `SRAV_CONTROL:       aluout_simple = $signed(src_bE) >>> src_aE[4:0];

            `SLL_CONTROL:    aluout_simple = src_bE << sa; //移位sa
            `SRL_CONTROL:    aluout_simple = src_bE >> sa;
            `SRA_CONTROL:    aluout_simple = $signed(src_bE) >>> sa;

            `LUI_CONTROL:       aluout_simple = {src_bE[15:0], 16'b0}; //取高16位
            5'b00000: aluout_simple = src_aE;  // do nothing

            default:    aluout_simple = 32'b0;
        endcase
    end
	mul mul(src_aE,src_bE,mul_sign,aluout_mul);

    // 除法
	assign div_sign = (alucontrolE == `DIV_CONTROL);
	assign div_vaild = (alucontrolE == `DIV_CONTROL || alucontrolE == `DIVU_CONTROL);

	div div(
		.clk(~clk),
		.rst(rst),
        .flush(flushE),
		.a(src_aE),  //divident
		.b(src_bE),  //divisor
		.valid(div_vaild),
		.sign(div_sign),   //1 signed

		// .ready(ready),
		.div_stall(div_stallE),
		.result(aluout_div)
	);

endmodule
