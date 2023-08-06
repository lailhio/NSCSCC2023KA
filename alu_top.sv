`include "defines2.vh"

module alu_top(
    input wire clk, rst,stall_masterE,flush_masterE,
    input wire [31:0] src1_aE, src1_bE,
    input wire [7:0] alucontrolE1, 
    // input wire [4:0] sa1, msbd1,
    input wire [31:0] src2_aE, src2_bE,
    input wire [7:0] alucontrolE2, 
    // input wire [4:0] sa1, msbd1,
    input wire flush_exception_masterM, DivMulEnE,//mfhiE, mfloE, 
    
    output wire alustallE,
    output reg [31:0] aluoutE1, 
    output reg overflowE1,
    output reg trapE1,
    output reg [31:0] aluoutE2, 
    output reg overflowE2,
    output reg trapE2
);
    
    wire [63:0] hilo_outE;
    wire [31:0] aluout_temp1, aluout_temp2;
    alu alu_1(clk, rst, src1_aE, src1_bE, alucontrolE1, hilo_outE, aluout_temp1, overflowE1, trapE1);
    alu alu_2(clk, rst, src2_aE, src2_bE, alucontrolE2, hilo_outE, aluout_temp2, overflowE2, trapE2);
    
    //支持两指令同读hilo、读写hilo、仅一条操作hilo，不支持写读。
    //支持两指令全部复写hilo
    //使用乘除法器
    wire two_is_md_hilo;
    assign two_is_md_hilo = (alucontrolE2==`MULT_CONTROL) | (alucontrolE2==`MULTU_CONTROL) |
        (alucontrolE2==`DIV_CONTROL) | (alucontrolE2==`DIVU_CONTROL) |
        (alucontrolE2==`MADD_CONTROL) | (alucontrolE2==`MADDU_CONTROL) | 
        (alucontrolE2==`MSUB_CONTROL) | (alucontrolE2==`MSUBU_CONTROL) ;
    
    wire one_is_md_hilo;
    assign one_is_md_hilo = (alucontrolE1==`MULT_CONTROL) | (alucontrolE1==`MULTU_CONTROL) | 
        (alucontrolE1==`DIV_CONTROL) | (alucontrolE1==`DIVU_CONTROL) | 
        (alucontrolE1==`MADD_CONTROL) | (alucontrolE1==`MADDU_CONTROL) | 
        (alucontrolE1==`MSUB_CONTROL) | (alucontrolE1==`MSUBU_CONTROL);
    
    //请保证以下指令不会同时发出
    wire two_is_md;
    assign two_is_md = (alucontrolE2==`MUL_CONTROL);
    wire one_is_md;
    assign one_is_md = (alucontrolE1==`MUL_CONTROL);
    
    //支持mthi、mtlo双发
    reg [63:0] hilo_in_muldiv_temp;
    wire [63:0] hilo_in_muldiv;
    wire [31:0]re_wite_hi, re_wite_lo;
    wire hilo_writeE;
    reg hilo_writeE_temp;
    assign hilo_writeE = (alucontrolE1==`MTHI_CONTROL) | (alucontrolE1==`MTLO_CONTROL) | (alucontrolE2==`MTHI_CONTROL) | (alucontrolE2==`MTLO_CONTROL) | hilo_writeE_temp;
    assign re_wite_hi = (alucontrolE2==`MTHI_CONTROL) ? src2_aE : (alucontrolE1==`MTHI_CONTROL) & ~two_is_md_hilo ? src1_aE : hilo_in_muldiv_temp[63:32];
    assign re_wite_lo = (alucontrolE2==`MTLO_CONTROL) ? src2_aE : (alucontrolE1==`MTLO_CONTROL) & ~two_is_md_hilo ? src1_aE : hilo_in_muldiv_temp[31:0];
    assign hilo_in_muldiv = {re_wite_hi,re_wite_lo};

    //乘除法,不支持两指令同时乘除
    wire [31:0] md_src_a, md_src_b;
    wire [7:0] md_alucontrol;
    assign md_src_a = two_is_md_hilo ? src2_aE : one_is_md_hilo ? src1_aE : 32'b0;
    assign md_src_b = two_is_md_hilo ? src2_bE : one_is_md_hilo ? src1_bE : 32'b0;
    assign md_alucontrol = two_is_md_hilo ? alucontrolE2 : one_is_md_hilo ? alucontrolE1 : 8'b0;

    wire [63:0] aluout_div; 
    wire [63:0] aluout_mul;
    reg mul_sign;
    reg div_sign; 
	wire ready_div;
    wire ready_mul;
    reg mul_startE;
    reg div_startE;
    assign alustallE = DivMulEnE & ~ready_div & ~ready_mul;

    always @(*) begin
        mul_sign =1'b0;
        div_sign =1'b0;
        mul_startE =1'b0;
        div_startE  =1'b0;
        hilo_writeE_temp = 1'b0;
        case(md_alucontrol)
            `MULT_CONTROL  : begin
                mul_sign = 1'b1;
                if(ready_mul) begin 
                    mul_startE = 1'b0;
                    hilo_writeE_temp = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                end
            end
            `MULTU_CONTROL  : begin
                mul_sign = 1'b0;
                if(ready_mul) begin 
                    mul_startE = 1'b0;
                    hilo_writeE_temp = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                end
            end
            `DIV_CONTROL :begin
                if(ready_div) begin 
                    div_startE = 1'b0;
                    hilo_writeE_temp = 1'b1;
                end
                else begin
                    div_sign = 1'b1;
                    div_startE = 1'b1;
                end
            end
            `DIVU_CONTROL :begin
                if(ready_div) begin 
                    div_startE = 1'b0;
                    hilo_writeE_temp = 1'b1;
                end
                else begin
                    div_sign = 1'b0;
                    div_startE = 1'b1;
                end
            end
            `MUL_CONTROL:    begin
                mul_sign = 1'b1;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    hilo_writeE_temp = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                end
            end
            `MADD_CONTROL:  begin
                mul_sign = 1'b1;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    hilo_writeE_temp = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                end
            end
            `MADDU_CONTROL: begin
                mul_sign = 1'b0;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    hilo_writeE_temp = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                end
            end
            `MSUB_CONTROL:  begin
                mul_sign = 1'b1;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    hilo_writeE_temp = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                end
            end
            `MSUBU_CONTROL:  begin
                mul_sign = 1'b0;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    hilo_writeE_temp = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                end
            end
            default: begin
            end
        endcase
    end
    always @(*) begin
        case(md_alucontrol)
            `MULT_CONTROL, `MULTU_CONTROL, `MUL_CONTROL  : begin
                hilo_in_muldiv_temp = aluout_mul;
            end
            `DIV_CONTROL, `DIVU_CONTROL :begin
                hilo_in_muldiv_temp = aluout_div;
            end
            `MTHI_CONTROL: begin
                hilo_in_muldiv_temp = {md_src_a, 32'b0};
            end
            `MTLO_CONTROL: begin
                hilo_in_muldiv_temp = {32'b0, md_src_a};
            end
            `MADD_CONTROL:  begin
                hilo_in_muldiv_temp = hilo_outE + aluout_mul;
            end
            `MADDU_CONTROL: begin
                hilo_in_muldiv_temp = hilo_outE + aluout_mul;
            end
            `MSUB_CONTROL:  begin
                hilo_in_muldiv_temp = hilo_outE - aluout_mul;
            end
            `MSUBU_CONTROL:  begin
                hilo_in_muldiv_temp = hilo_outE - aluout_mul;
            end
            default:    hilo_in_muldiv_temp = 64'b0;
        endcase
    end
    mul mul(
		.clk(clk),
		.rst(rst),
        .flush(flushE),
		.opdata1_i(src_aE),  
		.opdata2_i(src_bE),  
		.start_i(mul_startE),
		.signed_mul_i(mul_sign),   

		.ready_o(ready_mul),
		.result_o(aluout_mul)
	);
    

	div div(
		.clk(clk),
		.rst(rst),
        .flush(flushE),
		.opdata1_i(src_aE),  //divident
		.opdata2_i(src_bE),  //divisor
		.start_i(div_startE),
        .annul_i(0),
		.signed_div_i(div_sign),   //1 signed

		// .ready_div(ready_div),
		.ready_o(ready_div),
		.result_o(aluout_div)
	);

// hilo
    hilo hilo(clk,rst , hilo_writeE & ~flush_exceptionM  , hilo_in_muldiv, hilo_outE );

endmodule
