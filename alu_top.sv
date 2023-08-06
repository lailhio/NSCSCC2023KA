`include "defines2.vh"

module alu_top(
    input wire clk, rst, flush_masterE, flush_slaveE, 
    input wire [31:0] src1_aE, src1_bE,
    input wire [7:0] alucontrolE1, 
    input wire [7:0] alucontrolE2, 
    // input wire [4:0] sa1, msbd1,
    input wire [31:0] src2_aE, src2_bE,
    // input wire [4:0] sa1, msbd1,
    input wire DivMulEn1, DivMulEn2,
    
    output wire alustallE,
    output reg overflowE1,
    output reg overflowE2,
    output reg trapE1,
    output reg trapE2, 
    output reg [31:0] aluoutE1, 
    output reg [31:0] aluoutE2
);
    
    wire [63:0] hilo_outE;
    wire [31:0] aluout_temp1, aluout_temp2;
    alu alu_1(clk, rst, src1_aE, src1_bE, alucontrolE1, hilo_outE, aluout_temp1, overflowE1, trapE1);
    alu alu_2(clk, rst, src2_aE, src2_bE, alucontrolE2, hilo_outE, aluout_temp2, overflowE2, trapE2);
    
    
    //支持mthi、mtlo双发
    reg [63:0] hilo_in_muldiv;
    wire hilo_writeE;

    //乘除法,不支持两指令同时乘除
    wire [31:0] md_src_a, md_src_b;

    wire [63:0] aluout_div; 
    wire [63:0] aluout_mul;
    reg mul_sign;
    reg div_sign; 
	wire ready_div;
    wire ready_mul;
    reg mul_startE;
    reg div_startE;
    assign alustallE = (DivMulEn1|DivMulEn2) & ~ready_div & ~ready_mul;

    always @(*) begin
        mul_sign =1'b0;
        div_sign =1'b0;
        mul_startE =1'b0;
        div_startE  =1'b0;
        hilo_writeE = 1'b0;
        case(alucontrolE1)
            `MULT_CONTROL, `MADD_CONTROL, `MSUB_CONTROL: begin
                case(alucontrolE2)

                    mul_sign = 1'b1;
                    if(ready_mul) begin 
                        mul_startE = 1'b0;
                        hilo_writeE = 1'b1;
                    end
                    else begin
                        mul_startE = 1'b1;
                    end
                
                endcase
            end
            `MULTU_CONTROL, `MULTU_CONTROL, `MADDU_CONTROL, `MADDU_CONTROL,
            `MSUBU_CONTROL, `MSUBU_CONTROL: begin
                mul_sign = 1'b0;
                if(ready_mul) begin 
                    mul_startE = 1'b0;
                    hilo_writeE = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                end
            end
            `DIV_CONTROL, `DIV_CONTROL:begin
                div_sign = 1'b1;
                if(ready_div) begin 
                    div_startE = 1'b0;
                    hilo_writeE = 1'b1;
                end
                else begin
                    div_startE = 1'b1;
                end
            end
            `DIVU_CONTROL, `DIVU_CONTROL:begin
                div_sign = 1'b0;
                if(ready_div) begin 
                    div_startE = 1'b0;
                    hilo_writeE = 1'b1;
                end
                else begin
                    div_startE = 1'b1;
                end
            end
            `MUL_CONTROL, `MUL_CONTROL:begin
                mul_sign = 1'b1;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    hilo_writeE = 1'b1;
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
                hilo_in_muldiv = aluout_mul;
            end
            `DIV_CONTROL, `DIVU_CONTROL :begin
                hilo_in_muldiv = aluout_div;
            end
            `MTHI_CONTROL: begin
                hilo_in_muldiv = {md_src_a, 32'b0};
            end
            `MTLO_CONTROL: begin
                hilo_in_muldiv = {32'b0, md_src_a};
            end
            `MADD_CONTROL:  begin
                hilo_in_muldiv = hilo_outE + aluout_mul;
            end
            `MADDU_CONTROL: begin
                hilo_in_muldiv = hilo_outE + aluout_mul;
            end
            `MSUB_CONTROL:  begin
                hilo_in_muldiv = hilo_outE - aluout_mul;
            end
            `MSUBU_CONTROL:  begin
                hilo_in_muldiv = hilo_outE - aluout_mul;
            end
            default:    hilo_in_muldiv = 64'b0;
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
