`include "defines2.vh"

module alu_new(
    input wire clk, rst,stall_masterE,flush_masterE,
    input wire [31:0] src_aE1, src_bE1,
    input wire [7:0] alucontrolE1, 
    // input wire [4:0] sa1, msbd1,
    input wire [31:0] src_aE2, src_bE2,
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
    alu1 alu_1(clk, rst, src_aE1, src_bE1, alucontrolE1, hilo_outE, aluout_temp1, overflowE1, trapE1);
    alu2 alu_2(clk, rst, src_aE2, src_bE2, alucontrolE2, hilo_outE, aluout_temp2, overflowE2, trapE2);
    
    //支持两指令同读hilo、读写hilo、仅一条操作hilo，不支持写读。
    //支持两指令全部复写hilo
    wire two_is_md;
    assign two_is_md = (alucontrolE2==`MULT_CONTROL) | (alucontrolE2==`MULTU_CONTROL) |
    (alucontrolE2==`DIV_CONTROL) | (alucontrolE2==`DIVU_CONTROL) |
    (alucontrolE2==`MUL_CONTROL) | (alucontrolE2==`MADD_CONTROL) |
    (alucontrolE2==`MADDU_CONTROL) | (alucontrolE2==`MSUB_CONTROL) |
    (alucontrolE2==`MSUBU_CONTROL) ;
    wire one_is_md;
    assign one_is_md = ((alucontrolE1==`MULT_CONTROL) | (alucontrolE1==`MULTU_CONTROL) | 
    (alucontrolE1==`DIV_CONTROL) | (alucontrolE1==`DIVU_CONTROL) | 
    (alucontrolE1==`MUL_CONTROL) | (alucontrolE1==`MADD_CONTROL) | 
    (alucontrolE1==`MADDU_CONTROL) | (alucontrolE1==`MSUB_CONTROL) | 
    (alucontrolE1==`MSUBU_CONTROL)) & ~two_is_md ;
    
    //支持mthi、mtlo双发
    reg [63:0] hilo_in_muldiv_temp;
    wire [63:0] hilo_in_muldiv;
    wire [31:0]re_wite_hi, re_wite_lo;
    assign re_wite_hi = (alucontrolE2==`MTHI_CONTROL) ? src_aE2 : (alucontrolE1==`MTHI_CONTROL) & ~two_is_md ? src_aE1 : hilo_in_muldiv_temp[63:32];
    assign re_wite_lo = (alucontrolE2==`MTLO_CONTROL) ? src_aE2 : (alucontrolE1==`MTLO_CONTROL) & ~two_is_md ? src_aE1 : hilo_in_muldiv_temp[31:0];
    assign hilo_in_muldiv = {re_wite_hi,re_wite_lo};

    //乘除法,不支持两指令同时乘除
    wire [31:0] md_src_a, md_src_b;
    wire [7:0] md_alucontrol;
    wire [31:0] aluout_md;
    assign md_src_a = two_is_md ? src_aE2 : one_is_md ? src_aE1 : 32'b0;
    assign md_src_b = two_is_md ? src_bE2 : one_is_md ? src_bE1 : 32'b0;
    assign md_alucontrol = two_is_md ? alucontrolE2 : one_is_md ? alucontrolE1 : 8'b0;
    wire two_need_out;
    assign two_need_out = (alucontrolE2==`MUL_CONTROL)
    wire one_need_out;
    assign one_need_out = (alucontrolE1==`MUL_CONTROL) & ~two_is_md;

    //实际输出port
    assign aluoutE1 = one_need_out ? aluout_md : aluout_temp1;
    assign aluoutE2 = two_need_out ? aluout_md : aluout_temp2;


    wire [63:0] aluout_div; 
    wire [63:0] aluout_mul;
    
    reg mul_sign;
    reg div_sign; 
	wire ready_div;
    wire ready_mul;
    reg mul_startE;
    reg div_startE;
    reg hilo_writeE;
   
    assign alustallE = DivMulEnE & ~ready_div & ~ready_mul;

    always @(*) begin
        mul_sign =1'b0;
        div_sign =1'b0;
        mul_startE =1'b0;
        div_startE  =1'b0;
        hilo_writeE = 1'b0;
        case(md_alucontrol)
            `MULT_CONTROL  : begin
                mul_sign = 1'b1;
                if(ready_mul) begin 
                    mul_startE = 1'b0;
                    // hilo_in_muldiv_temp = aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                    // hilo_in_muldiv_temp = 64'b0;
                end
            end
            `MULTU_CONTROL  : begin
                mul_sign = 1'b0;
                if(ready_mul) begin 
                    mul_startE = 1'b0;
                    // hilo_in_muldiv_temp = aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    
                    mul_startE = 1'b1;
                    // hilo_in_muldiv_temp = 64'b0;
                end
            end
            `DIV_CONTROL :begin
                if(ready_div) begin 
                    div_startE = 1'b0;
                    // hilo_in_muldiv_temp = aluout_div;
                    hilo_writeE = 1'b1;
                end
                else begin
                    div_sign = 1'b1;
                    div_startE = 1'b1;
                    // hilo_in_muldiv_temp = 64'b0;
                end
            end
            `DIVU_CONTROL :begin
                if(ready_div) begin 
                    div_startE = 1'b0;
                    // hilo_in_muldiv_temp = aluout_div;
                    hilo_writeE = 1'b1;
                end
                else begin
                    div_sign = 1'b0;
                    div_startE = 1'b1;
                    // hilo_in_muldiv_temp = 64'b0;
                end
            end
            `MUL_CONTROL:    begin
                mul_sign = 1'b1;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    // hilo_in_muldiv_temp = aluout_mul[31:0];
                    hilo_writeE = 1'b1;
                    aluout_md = aluout_mul[31:0];
                end
                else begin
                    mul_startE = 1'b1;
                    // hilo_in_muldiv_temp = 64'b0;
                end
            end
            `MADD_CONTROL:  begin
                mul_sign = 1'b1;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    // hilo_in_muldiv_temp = hilo_outE + aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                    // hilo_in_muldiv_temp = 64'b0;
                end
            end
            `MADDU_CONTROL: begin
                mul_sign = 1'b0;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    // hilo_in_muldiv_temp = hilo_outE + aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    
                    mul_startE = 1'b1;
                    // hilo_in_muldiv_temp = 64'b0;
                end
            end
            `MSUB_CONTROL:  begin
                mul_sign = 1'b1;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    // hilo_in_muldiv_temp = hilo_outE - aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                    // hilo_in_muldiv_temp = 64'b0;
                end
            end
            `MSUBU_CONTROL:  begin
                mul_sign = 1'b0;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    // hilo_in_muldiv_temp = hilo_outE - aluout_mul;
                    hilo_writeE = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                    // hilo_in_muldiv_temp = 64'b0;
                end
            end
            default: begin
            end
        endcase
    end
    always @(*) begin
        case(alucontrolE)
            `MULT_CONTROL, `MULTU_CONTROL, `MUL_CONTROL  : begin
                hilo_in_muldiv_temp = aluout_mul;
            end
            `DIV_CONTROL, `DIVU_CONTROL :begin
                hilo_in_muldiv_temp = aluout_div;
            end
            `MTHI_CONTROL: begin
                hilo_in_muldiv_temp = {src_aE, 32'b0};
            end
            `MTLO_CONTROL: begin
                hilo_in_muldiv_temp = {32'b0, src_aE};
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
        .flush(flush_masterE),
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
        .flush(flush_masterE),
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
    hilo_new hilo(clk,rst, hilo_writeE & ~flush_exception_masterM , hilo_in_muldiv , hilo_outE );

endmodule
