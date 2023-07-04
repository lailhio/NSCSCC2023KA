`timescale 1ns / 1ps


`include "defines2.vh"
module alu(
    input wire clk, rst,stallE,
    input wire flushE,
    input wire [31:0] src_aE, src_bE,
    input wire [4:0] alucontrolE, 
    input wire [4:0] sa, 
    
    output wire hilo_writeE,
    output wire [1:0]hilo_selectE,
    output wire alustallE,
    output wire [63:0] aluoutE, 
    output wire overflowE
);
    wire [63:0] aluout_div; 
    wire [63:0] aluout_mul;
    wire mul_sign;
    wire mul_valid;  
    wire mul_stallE;
    wire div_sign; 
	wire div_valid; 
    wire div_stallE;
	wire ready_div;
    wire ready_mul;
    reg [31:0] aluout_simple; 
    reg carry_bit; 

    
    //aluout
    assign aluoutE = ({64{div_valid}} & aluout_div)
                    | ({64{mul_valid}} & aluout_mul)
                    | ({64{~mul_valid & ~div_valid}} & {32'b0, aluout_simple})
                    | ({64{~|(alucontrolE ^ `MTHI_CONTROL)}} & {src_aE, 32'b0})
                    | ({64{~|(alucontrolE ^ `MTLO_CONTROL)}} & {32'b0, src_aE});

    assign overflowE = ((~|(alucontrolE^`ADD_CONTROL)) | (~|(alucontrolE^`SUB_CONTROL))) & 
                        (carry_bit ^ aluout_simple[31]);

   
    always @(*) begin
        carry_bit = 0;
        case(alucontrolE)
            `AND_CONTROL:       aluout_simple = src_aE & src_bE;
            `OR_CONTROL:        aluout_simple = src_aE | src_bE;
            `NOR_CONTROL:       aluout_simple =~(src_aE | src_bE);
            `XOR_CONTROL:       aluout_simple = src_aE ^ src_bE;

            `ADD_CONTROL:       {carry_bit, aluout_simple} = {src_aE[31], src_aE} + {src_bE[31], src_bE};
            `ADDU_CONTROL:      aluout_simple = src_aE + src_bE;
            `SUB_CONTROL:       {carry_bit, aluout_simple} = {src_aE[31], src_aE} - {src_bE[31], src_bE};
            `SUBU_CONTROL:      aluout_simple = src_aE - src_bE;

            `SLT_CONTROL:       aluout_simple = $signed(src_aE) < $signed(src_bE); 
            `SLTU_CONTROL:      aluout_simple = src_aE < src_bE; 

            `SLLV_CONTROL:       aluout_simple = src_bE << src_aE[4:0]; 
            `SRLV_CONTROL:       aluout_simple = src_bE >> src_aE[4:0];
            `SRAV_CONTROL:       aluout_simple = $signed(src_bE) >>> src_aE[4:0];

            `SLL_CONTROL:    aluout_simple = src_bE << sa; 
            `SRL_CONTROL:    aluout_simple = src_bE >> sa;
            `SRA_CONTROL:    aluout_simple = $signed(src_bE) >>> sa;

            `LUI_CONTROL:       aluout_simple = {src_bE[15:0], 16'b0};
            5'b00000: aluout_simple = src_aE;  // do nothing

            default:    aluout_simple = 32'b0;
        endcase
    end
    assign hilo_selectE={(~|(alucontrolE[4:2] ^ 3'b111)),(~|(alucontrolE ^ `MTHI_CONTROL))};//高位1表示是mhl指令，0表示是乘除法
                                                                                            //低位1表示是用hi，0表示用lo
    assign hilo_writeE  =  ready_div | ready_mul |
                        // ((~|(alucontrolE[4:1]^ 4'b1100)) | 
                        ((~|({alucontrolE[4:2],alucontrolE[0]}^ 4'b1111)) & ~stallE);

    assign mul_sign = ~|(alucontrolE ^ `MULT_CONTROL);
    assign mul_valid = ~|(alucontrolE[4:1]^4'b1100);
    assign mul_stallE= ready_mul ? 0 : mul_valid; 
    
    assign div_sign = ~|(alucontrolE ^ `DIV_CONTROL);
    assign div_valid = ~|(alucontrolE[4:1] ^ 4'b1101);
    assign div_stallE= ready_div ? 0 : div_valid; 
    assign alustallE = mul_stallE | div_stallE;

    mul mul(
		.clk(~clk),
		.rst(rst),
        .flush(flushE),
		.opdata1_i(src_aE),  
		.opdata2_i(src_bE),  
		.start_i(mul_stallE),
		.signed_mul_i(mul_sign),   

		.ready_o(ready_mul),
		.result_o(aluout_mul)
	);
    

	div div(
		.clk(~clk),
		.rst(rst),
        .flush(flushE),
		.opdata1_i(src_aE),  //divident
		.opdata2_i(src_bE),  //divisor
		.start_i(div_stallE),
        .annul_i(0),
		.signed_div_i(div_sign),   //1 signed

		// .ready_div(ready_div),
		.ready_o(ready_div),
		.result_o(aluout_div)
	);

endmodule
