`include "defines2.vh"

module alu_top(
    input wire clk, rst, flush_masterE, flush_slaveE, 
    input wire [31:0] src1_aE, src1_bE,
    input wire [31:0] src2_aE, src2_bE,
    input wire [7:0] alucontrolE1, 
    input wire [7:0] alucontrolE2, 
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
    reg [31:0] MulDivOp1, MulDivOp2;
    reg flushE;
    alu alu_1(clk, rst, src1_aE, src1_bE, alucontrolE1, aluout_mul, hilo_outE, aluoutE1, overflowE1, trapE1);
    alu alu_2(clk, rst, src2_aE, src2_bE, alucontrolE2, aluout_mul, hilo_outE, aluoutE2, overflowE2, trapE2);
    
    
    //支持mthi、mtlo双发
    reg [63:0] hilo_in_muldiv;
    wire hilo_writeE;

    //乘除法,不支持两指令同时乘除

    wire [63:0] aluout_div; 
    wire [63:0] aluout_mul;
    reg mul_sign;
    reg div_sign; 
	wire ready_div;
    wire ready_mul;
    reg mul_startE;
    reg div_startE;
    assign alustallE = (DivMulEn1 | DivMulEn2) & ~ready_div & ~ready_mul;

    always @(*) begin
        mul_sign =1'b0;
        div_sign =1'b0;
        mul_startE =1'b0;
        div_startE  =1'b0;
        hilo_writeE = 1'b0;
        case(alucontrolE1)
            `MULT_CONTROL, `MADD_CONTROL, `MSUB_CONTROL: begin
                mul_sign = 1'b1;
                MulDivOp1 <= src1_aE;
                MulDivOp2 <= src1_bE;
                flushE <= flush_masterE;
                if(ready_mul) begin 
                    mul_startE = 1'b0;
                    hilo_writeE = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                end
            end
            `MULTU_CONTROL, `MADDU_CONTROL, `MSUBU_CONTROL: begin
                mul_sign = 1'b0;
                MulDivOp1 <= src1_aE;
                MulDivOp2 <= src1_bE;
                flushE <= flush_masterE;
                if(ready_mul) begin 
                    mul_startE = 1'b0;
                    hilo_writeE = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                end
            end
            `DIV_CONTROL: begin
                div_sign = 1'b1;
                MulDivOp1 <= src1_aE;
                MulDivOp2 <= src1_bE;
                flushE <= flush_masterE;
                if(ready_div) begin 
                    div_startE = 1'b0;
                    hilo_writeE = 1'b1;
                end
                else begin
                    div_startE = 1'b1;
                end
            end
            `DIVU_CONTROL: begin
                div_sign = 1'b0;
                MulDivOp1 <= src1_aE;
                MulDivOp2 <= src1_bE;
                flushE <= flush_masterE;
                if(ready_div) begin 
                    div_startE = 1'b0;
                    hilo_writeE = 1'b1;
                end
                else begin
                    div_startE = 1'b1;
                end
            end
            `MUL_CONTROL: begin
                mul_sign = 1'b1;
                MulDivOp1 <= src1_aE;
                MulDivOp2 <= src1_bE;
                flushE <= flush_masterE;
                if(ready_mul) begin
                    mul_startE = 1'b0;
                    hilo_writeE = 1'b1;
                end
                else begin
                    mul_startE = 1'b1;
                end
            end
            default: begin
                case(alucontrolE2)
                    `MULT_CONTROL, `MADD_CONTROL, `MSUB_CONTROL: begin
                        mul_sign = 1'b1;
                        MulDivOp1 <= src2_aE;
                        MulDivOp2 <= src2_bE;
                        flushE <= flush_slaveE;
                        if(ready_mul) begin 
                            mul_startE = 1'b0;
                            hilo_writeE = 1'b1;
                        end
                        else begin
                            mul_startE = 1'b1;
                        end
                    end
                    `MULTU_CONTROL, `MADDU_CONTROL, `MSUBU_CONTROL: begin
                        mul_sign = 1'b0;
                        MulDivOp1 <= src2_aE;
                        MulDivOp2 <= src2_bE;
                        flushE <= flush_slaveE;
                        if(ready_mul) begin 
                            mul_startE = 1'b0;
                            hilo_writeE = 1'b1;
                        end
                        else begin
                            mul_startE = 1'b1;
                        end
                    end
                    `DIV_CONTROL: begin
                        div_sign = 1'b1;
                        MulDivOp1 <= src2_aE;
                        MulDivOp2 <= src2_bE;
                        flushE <= flush_slaveE;
                        if(ready_div) begin 
                            div_startE = 1'b0;
                            hilo_writeE = 1'b1;
                        end
                        else begin
                            div_startE = 1'b1;
                        end
                    end
                    `DIVU_CONTROL: begin
                        div_sign = 1'b0;
                        MulDivOp1 <= src2_aE;
                        MulDivOp2 <= src2_bE;
                        flushE <= flush_slaveE;
                        if(ready_div) begin 
                            div_startE = 1'b0;
                            hilo_writeE = 1'b1;
                        end
                        else begin
                            div_startE = 1'b1;
                        end
                    end
                    `MUL_CONTROL: begin
                        mul_sign = 1'b1;
                        MulDivOp1 <= src2_aE;
                        MulDivOp2 <= src2_bE;
                        flushE <= flush_slaveE;
                        if(ready_mul) begin
                            mul_startE = 1'b0;
                            hilo_writeE = 1'b1;
                        end
                        else begin
                            mul_startE = 1'b1;
                        end
                    end
                    default: begin
                        hilo_writeE <= 0;
                        mul_startE <= 0;
                        mul_sign <= 0;
                        div_startE <= 0;
                        div_sign <= 0;
                        MulDivOp1 <= 32'b0;
                        MulDivOp2 <= 32'b0;
                        flushE <= 0;
                    end
                endcase
            end
        endcase
    end
    always @(*) begin
        case(alucontrolE1)
            `MULT_CONTROL, `MULTU_CONTROL : begin
                hilo_in_muldiv = aluout_mul;
            end
            `DIV_CONTROL, `DIVU_CONTROL :begin
                hilo_in_muldiv = aluout_div;
            end
            `MTHI_CONTROL: begin
                hilo_in_muldiv = {src1_aE, 32'b0};
            end
            `MTLO_CONTROL: begin
                hilo_in_muldiv = {32'b0, src1_aE};
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
            default: begin
                case(alucontrolE2)
                    `MULT_CONTROL, `MULTU_CONTROL : begin
                        hilo_in_muldiv = aluout_mul;
                    end
                    `DIV_CONTROL, `DIVU_CONTROL :begin
                        hilo_in_muldiv = aluout_div;
                    end
                    `MTHI_CONTROL: begin
                        hilo_in_muldiv = {src2_aE, 32'b0};
                    end
                    `MTLO_CONTROL: begin
                        hilo_in_muldiv = {32'b0, src2_aE};
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
                    default: hilo_in_muldiv<= 32'b0;
                endcase
            end
        endcase
    end
    mul mul(
		.clk(clk),
		.rst(rst),
        .flush(flushE),
		.opdata1_i(MulDivOp1),  
		.opdata2_i(MulDivOp2),  
		.start_i(mul_startE),
		.signed_mul_i(mul_sign),   

		.ready_o(ready_mul),
		.result_o(aluout_mul)
	);
    

	div div(
		.clk(clk),
		.rst(rst),
        .flush(flushE),
		.opdata1_i(MulDivOp1),  //divident
		.opdata2_i(MulDivOp2),  //divisor
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
